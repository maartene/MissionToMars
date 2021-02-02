//
//  File.swift
//  
//
//  Created by Maarten Engels on 08/12/2020.
//

import Foundation
import Vapor
import SotoS3

public extension Application {
    var aws: AWS {
        .init(application: self)
    }

    struct AWS {
        struct ClientKey: StorageKey {
            typealias Value = AWSClient
        }

        public var client: AWSClient {
            get {
                guard let client = self.application.storage[ClientKey.self] else {
                    fatalError("AWSClient not setup. Use application.aws.client = ...")
                }
                return client
            }
            nonmutating set {
                self.application.storage.set(ClientKey.self, to: newValue) {
                    try $0.syncShutdown()
                }
            }
        }

        let application: Application
    }
}

public extension Request {
    var aws: AWS {
        .init(request: self)
    }

    struct AWS {
        var client: AWSClient {
            return request.application.aws.client
        }

        let request: Request
    }
}

public struct SimulationFileInfo: Content {
    let fileName: String
    //let creationDate: String
    let modifiedDate: String
    let isCurrentSimulation: Bool
}

public enum ApplicationAWSErrors: Error {
    case other(message: String)
}

public extension Application {
    func purgeOldFiles(on req: Request, keepAmount: Int) {
        
        _ = self.getFileList(on: req).map { fileList in
            print(fileList)
            
            let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
                        
            let s3 = S3(client: req.aws.client, region: nil, partition: AWSPartition.awsiso, endpoint: "https://m2m.ams3.digitaloceanspaces.com", timeout: nil, byteBufferAllocator: ByteBufferAllocator(), options: [])
            
            if fileList.count > keepAmount {
                let oldestFiles = fileList[keepAmount ..< fileList.count]
                
                let deleteRequests = oldestFiles.map { file in
                    S3.DeleteObjectRequest(bucket: bucket, key: file.fileName)
                }
                
                _ = deleteRequests.map { deleteRequest in
                    s3.deleteObject(deleteRequest, logger: self.logger, on: req.eventLoop)
                }
                
                self.logger.notice("Deleted the following files: \(oldestFiles)")
            } else {
                self.logger.notice("Not more (\(fileList.count)) than keep amount (\(keepAmount)) files present in bucket. Not deleting any files.")
            }
        }
    }

    func getFileList(on req: Request?) -> EventLoopFuture<[SimulationFileInfo]> {
        let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
                    
        let s3 = S3(client: self.aws.client, region: nil, partition: AWSPartition.awsiso, endpoint: "https://m2m.ams3.digitaloceanspaces.com", timeout: nil, byteBufferAllocator: ByteBufferAllocator(), options: [])
        //let s3 = S3(client: app.aws.client, accessKeyId: accessKey, secretAccessKey: secretKey, region: .euwest1, endpoint: "https://m2m.ams3.digitaloceanspaces.com")

        let listRequest = S3.ListObjectsRequest(bucket: "")

        return s3.listObjects(listRequest, logger: self.logger, on: req?.eventLoop).map { result in
        //return s3.listObjects(listRequest, on: req)  // .flatMap { result in
            let contents = result.contents ?? []
            let objects = contents.compactMap {$0}
                .filter { fileObject in
                    fileObject.key?.hasPrefix(bucket) ?? false
                }
                .map { fileObject -> SimulationFileInfo in
                    let fileName = fileObject.key?.split(separator: "/").last ?? "unknown"
                    
                    return SimulationFileInfo(fileName: String(fileName), modifiedDate: fileObject.lastModified?.description ?? "unknown", isCurrentSimulation: false)
                }.sorted { $0.modifiedDate > $1.modifiedDate }
            
            return objects
        }
    }

    func saveSimulationToSpace(on req: Request) -> EventLoopFuture<S3.CompleteMultipartUploadOutput> {
        let copy = self.simulation
        let dataDir = Environment.get("DATA_DIR") ?? ""
        
        guard let path = try? copy.save(path: dataDir) else {
            return req.eventLoop.makeFailedFuture(ApplicationAWSErrors.other(message: "Failed to locally save simulation backup in data dir \(dataDir)."))
        }
    
        let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
    
        let s3 = S3(client: self.aws.client, region: nil, partition: AWSPartition.awsiso, endpoint: "https://m2m.ams3.digitaloceanspaces.com", timeout: nil, byteBufferAllocator: ByteBufferAllocator(), options: [])

        let uploadRequest = S3.CreateMultipartUploadRequest(acl: .private, bucket: bucket, key: SIMULATION_FILENAME + "_\(Date().hashValue)" + ".json")
               
        return s3.multipartUpload(uploadRequest,
                                  partSize: 5*1024*1024,
                                  filename: path.path,
                                  on: req.eventLoop,
                                  progress: { progress in print(progress) }
                                      
             )
    }
    
    
    
    func loadSimulationFromSpace(fileName: String, on req: Request?) -> EventLoopFuture<Result<Simulation, Error>> {
        let dataDir = Environment.get("DATA_DIR") ?? ""
        let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
                
        let s3 = S3(client: self.aws.client, region: nil, partition: AWSPartition.awsiso, endpoint: "https://m2m.ams3.digitaloceanspaces.com", timeout: nil, byteBufferAllocator: ByteBufferAllocator(), options: [])
        //let s3 = S3(client: app.aws.client, accessKeyId: accessKey, secretAccessKey: secretKey, region: .euwest1, endpoint: "https://m2m.ams3.digitaloceanspaces.com")

        let downloadRequest = S3.GetObjectRequest(bucket: bucket, key: fileName)
        
        return s3.multipartDownload(downloadRequest,
                filename: dataDir + fileName,
                on: req?.eventLoop).map { size in
            self.logger.notice("Succesfully loaded simulation \(size) bytes.")
            
            guard let loadedSimulation =  Simulation.load(fileName: fileName, path: dataDir) else {
                self.logger.error("Error loading simulation")
                return .failure(ApplicationAWSErrors.other(message: "Error loading simulation"))
            }
                
            guard let adminPlayer = loadedSimulation.players.first(where: {$0.isAdmin}) else {
                return .failure(ApplicationAWSErrors.other(message: "Did not find any admin player in loaded simulation. Load failed."))
            }
            
            self.logger.notice("Loaded admin player with username: \(adminPlayer.name), email: \(adminPlayer.emailAddress) and id: \(adminPlayer.id)")
            return .success(loadedSimulation)
        }
    }
    
}

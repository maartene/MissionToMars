//
//  File.swift
//  
//
//  Created by Maarten Engels on 22/11/2020.
//

import Foundation
import Vapor
import Leaf
import SotoS3

func createAdminRoutes(_ app: Application) {
    app.get("admin", "state") { req in
        app.simulation.state.rawValue
    }
    
    let session = app.routes.grouped([
        SessionsMiddleware(session: app.sessions.driver),
        UserSessionAuthenticator(),
        UserCredentialsAuthenticator(),
    ])
    
    session.get("admin") { req -> EventLoopFuture<View> in
        return try adminPage(on: req, with: app.simulation, in: app)
    }

   
        
    session.get("admin", "leaveAdminMode") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard app.simulation.state == .admin else {
            throw Abort(.badRequest, reason: "Can only leave admin mode when simulation is in admin mode.")
        }
        
        app.simulation.state = .running
        return req.redirect(to: "/admin")
    }
        
    session.get("admin", "save") { req -> EventLoopFuture<Response> in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }

        let dataDir = Environment.get("DATA_DIR") ?? ""
        let path = try app.simulation.save(path: dataDir)
        let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
                
        let s3 = S3(client: app.aws.client, region: nil, partition: AWSPartition.awsiso, endpoint: "https://m2m.ams3.digitaloceanspaces.com", timeout: nil, byteBufferAllocator: ByteBufferAllocator(), options: [])
        //let s3 = S3(client: app.aws.client, accessKeyId: accessKey, secretAccessKey: secretKey, region: .euwest1, endpoint: "https://m2m.ams3.digitaloceanspaces.com")

        let uploadRequest = S3.CreateMultipartUploadRequest(acl: .private, bucket: bucket, key: SIMULATION_FILENAME + "_\(Date().hashValue)" + ".json")
           
        return s3.multipartUpload(uploadRequest,
                                  partSize: 5*1024*1024,
                                  filename: path.path,
                                  on: req.eventLoop,
                                  progress: { progress in print(progress) }
                                  ).map { result in
                                    app.logger.notice("Save result: \(result)")
                                    app.infoMessages[player.id] = "Succesfully saved: \(result.location ?? "unknown path")"
                                    return req.redirect(to: "/admin")
        }
    }
        
    session.get("admin", "enterAdminMode") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard app.simulation.state != .admin else {
            throw Abort(.badRequest, reason: "Can only enter admin mode when simulation is not already in admin mode.")
        }
        
        req.logger.notice("entering admin mode.")
        app.simulation.state = .admin
        return req.redirect(to: "/admin")
    }
    
    session.post("admin", "set", "motd") { req -> Response in
        let player = try req.getPlayerFromSession()
        
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        let message: String = try req.content.get(at: "motd")
        
        app.motd = message
        
        return req.redirect(to: "/admin")
    }
        
    session.get("admin", "bless", ":userName") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard let playerToBlessName = req.parameters.get("userName") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("userName") ?? "unknown") is not a valid string value.")
        }
        
        guard let playerToBless = app.simulation.players.first(where: {$0.name == playerToBlessName }) else {
            throw Abort(.notFound, reason: "Could not find player with name \(playerToBlessName).")
        }
        
        let blessedPlayer = playerToBless.bless()
        app.simulation = try app.simulation.replacePlayer(blessedPlayer)
        return req.redirect(to: "/admin")
    }

    session.get("admin", "unbless", ":userName") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard let playerToBlessName = req.parameters.get("userName") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("userName") ?? "unknown") is not a valid string value.")
        }
        
        guard let playerToBless = app.simulation.players.first(where: {$0.name == playerToBlessName }) else {
            throw Abort(.notFound, reason: "Could not find player with name \(playerToBlessName).")
        }
        
        let unblessedPlayer = playerToBless.unbless()
        app.simulation = try app.simulation.replacePlayer(unblessedPlayer)
        return req.redirect(to: "/admin")
    }
    
    session.get("admin", "give", "tech", ":userName") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard let playerToReceiveName = req.parameters.get("userName") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("userName") ?? "unknown") is not a valid string value.")
        }
        
        guard let playerToReceive = app.simulation.players.first(where: {$0.name == playerToReceiveName }) else {
            throw Abort(.notFound, reason: "Could not find player with name \(playerToReceiveName).")
        }
        
        let giftedPlayer = playerToReceive.extraTech(amount: 1000)
        app.simulation = try app.simulation.replacePlayer(giftedPlayer)
        return req.redirect(to: "/admin")
    }
    
    session.get("admin", "give", "cash", ":userName") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard let playerToReceiveName = req.parameters.get("userName") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("userName") ?? "unknown") is not a valid string value.")
        }
        
        guard let playerToReceive = app.simulation.players.first(where: {$0.name == playerToReceiveName }) else {
            throw Abort(.notFound, reason: "Could not find player with name \(playerToReceiveName).")
        }
        
        let giftedPlayer = playerToReceive.extraIncome(amount: 1_000_000)
        app.simulation = try app.simulation.replacePlayer(giftedPlayer)
        return req.redirect(to: "/admin")
    }
        
    session.get("admin", "load", "simulation", ":fileName") { req -> EventLoopFuture<Response> in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard app.simulation.state == .admin else {
            throw Abort(.badRequest, reason: "Loading of database is only allowed in 'Admin' state.")
        }
        
        guard let fileName = req.parameters.get("fileName") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("fileName") ?? "unknown") is not a valid string value.")
        }
        
        let dataDir = Environment.get("DATA_DIR") ?? ""
        let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
                
        let s3 = S3(client: app.aws.client, region: nil, partition: AWSPartition.awsiso, endpoint: "https://m2m.ams3.digitaloceanspaces.com", timeout: nil, byteBufferAllocator: ByteBufferAllocator(), options: [])
        //let s3 = S3(client: app.aws.client, accessKeyId: accessKey, secretAccessKey: secretKey, region: .euwest1, endpoint: "https://m2m.ams3.digitaloceanspaces.com")

        let downloadRequest = S3.GetObjectRequest(bucket: bucket, key: fileName)
        
        return s3.multipartDownload(downloadRequest,
                filename: dataDir + fileName,
                on: req.eventLoop).map { size in
            app.logger.notice("Succesfully loaded simulation \(size) bytes.") 
            
            guard let loadedSimulation =  Simulation.load(fileName: fileName, path: dataDir) else {
                app.errorMessages[player.id] = "Error loading simulation"
                req.logger.error("Error loading simulation")
                return req.redirect(to: "/admin")
            }
                
            guard let adminPlayer = loadedSimulation.players.first(where: {$0.isAdmin}) else {
                app.errorMessages[player.id] = "Did not find any admin player in loaded simulation. Load failed."
                return req.redirect(to: "/admin")
            }
                
            app.simulation = loadedSimulation
            req.logger.notice("Loaded admin player with username: \(adminPlayer.name), email: \(adminPlayer.emailAddress) and id: \(adminPlayer.id)")
            return req.redirect(to: "/")
        }
    }
}

func adminPage(on req: Request, with simulation: Simulation, in app: Application) throws -> EventLoopFuture<View> {
    struct FileInfo: Content {
        let fileName: String
        //let creationDate: String
        let modifiedDate: String
        let isCurrentSimulation: Bool
    }
    
    struct PlayerInfo: Content {
        let name: String
        let email: String
        let isAdmin: Bool
    }
        
    struct AdminContext: Content {
        let player: Player
        //let backupFiles: [FileInfo]
        let infoMessage: String?
        let errorMessage: String?
        let state: Simulation.SimulationState
        let players: [PlayerInfo]
        let motd: String
        let fileList: [FileInfo]
    }
    
    let player = try req.getPlayerFromSession()
    guard player.isAdmin else {
        throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
    }
    
    let players = simulation.players.map { player in
        PlayerInfo(name: player.name, email: player.emailAddress, isAdmin: player.isAdmin)
    }
    
    let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
            
    let s3 = S3(client: app.aws.client, region: nil, partition: AWSPartition.awsiso, endpoint: "https://m2m.ams3.digitaloceanspaces.com", timeout: nil, byteBufferAllocator: ByteBufferAllocator(), options: [])
    //let s3 = S3(client: app.aws.client, accessKeyId: accessKey, secretAccessKey: secretKey, region: .euwest1, endpoint: "https://m2m.ams3.digitaloceanspaces.com")

    let listRequest = S3.ListObjectsRequest(bucket: "")

    return s3.listObjects(listRequest, logger: req.logger, on: req.eventLoop) .flatMap { result in
    //return s3.listObjects(listRequest, on: req)  // .flatMap { result in
        let contents = result.contents ?? []
        let objects = contents.compactMap {$0}
            .filter { fileObject in
                fileObject.key?.hasPrefix(bucket) ?? false
            }
            .map { fileObject -> FileInfo in
                let fileName = fileObject.key?.split(separator: "/").last ?? "unknown"
                
                return FileInfo(fileName: String(fileName), modifiedDate: fileObject.lastModified?.description ?? "unknown", isCurrentSimulation: false)
            }.sorted { $0.modifiedDate > $1.modifiedDate }
        
        let context = AdminContext(player: player,
                                   //backupFiles: sortedFiles,
                                   infoMessage: app.infoMessages[player.id] ?? nil, errorMessage: app.errorMessages[player.id] ?? nil, state: app.simulation.state, players: players, motd: app.motd, fileList: objects)
        
        req.logger.info("File list retrieve complete.")
        
        
        return req.view.render("admin/admin", context)
    }
}

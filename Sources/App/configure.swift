import Vapor
import Leaf
import SotoS3

/// Called before your application initializes.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#configureswift)
public func configure(_ app: Application) throws {
    app.simulation = Simulation(id: UUID(), tickCount: 0, gameDate: Date(), nextUpdateDate: Date(), createDefaultAdminPlayer: true)
    //app.simulation.state = .running
    
    // Register routes to the router
    try routes(app)

    // Configure LEAF
    app.views.use(.leaf)

    if (Environment.get("ENVIRONMENT") ?? "").uppercased() == "PRODUCTION" {
        app.environment = .production
    } else {
        app.environment = .development
    }
    app.logger.notice("Running in environment: \(app.environment)")
    
    // Configure custom tags
    app.leaf.tags[CashTag.name] = CashTag()
    app.leaf.tags[TechnologyUnlocksImprovementsTag.name] = TechnologyUnlocksImprovementsTag()
    app.leaf.tags[TechnologyUnlocksTechnologiesTag.name] = TechnologyUnlocksTechnologiesTag()
    app.leaf.tags[TechnologyUnlocksComponentsTag.name] = TechnologyUnlocksComponentsTag()
    app.leaf.tags[DecimalTag.name] = DecimalTag()
    app.leaf.tags[ZeroDecimalTag.name] = ZeroDecimalTag()
    app.leaf.tags[ComponentPrereqTag.name] = ComponentPrereqTag()
    app.leaf.tags[DateTag.name] = DateTag()
    app.leaf.tags[ImprovementEffectTag.name] = ImprovementEffectTag()
    app.leaf.tags[ImprovementTagTag.name] = ImprovementTagTag()
    app.leaf.tags[TechnologyEffectsTag.name] = TechnologyEffectsTag()
    
 
    // Register middleware (file serving and sessions)
    app.middleware.use(FileMiddleware(publicDirectory: "Public"))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.middleware.use(app.sessions.middleware)
    
    if let accessKey = Environment.get("DO_SPACES_ACCESS_KEY"), let secretKey = Environment.get("DO_SPACES_SECRET") {
        let client = AWSClient(credentialProvider: .static(accessKeyId: accessKey, secretAccessKey: secretKey), httpClientProvider: .shared(app.http.client.shared))
        
        app.aws.client = client
    } else {
        app.logger.warning("No Digital Ocean Spaces credentials provided. Save/load actions might fail.")
        app.aws.client = AWSClient(httpClientProvider: .shared(app.http.client.shared))
    }
    
    app.lifecycle.use(LoadSimulation())
}


struct LoadSimulation: LifecycleHandler {
    // Called before application boots.
    func willBoot(_ app: Application) throws {
        struct FileInfo: Content {
            let fileName: String
            //let creationDate: String
            let modifiedDate: String
            let isCurrentSimulation: Bool
        }
        
        let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
        
        let s3 = S3(client: app.aws.client, region: nil, partition: AWSPartition.awsiso, endpoint: "https://m2m.ams3.digitaloceanspaces.com", timeout: nil, byteBufferAllocator: ByteBufferAllocator(), options: [])
        
        let listRequest = S3.ListObjectsRequest(bucket: "")

        guard let result = try? s3.listObjects(listRequest).wait() else {
            app.logger.error("Unable to retrieve simulation list.")
            return
        }

        let contents = result.contents ?? []
        let objects = contents.compactMap {$0}
            .filter { fileObject in
                fileObject.key?.hasPrefix(bucket) ?? false
            }
            .map { fileObject -> FileInfo in
                let fileName = fileObject.key?.split(separator: "/").last ?? "unknown"
                
                return FileInfo(fileName: String(fileName), modifiedDate: fileObject.lastModified?.description ?? "unknown", isCurrentSimulation: false)
            }.sorted { $0.modifiedDate > $1.modifiedDate }
        
        app.logger.notice("Found \(objects.count) possible files to load as simulation.")
        
        // get the latest simulation
        guard let simulationFile = objects.first else {
            app.logger.error("No loadable simulation found.")
            return
        }
        
        let simulationFileName = simulationFile.fileName
        
        app.logger.notice("Attempting to load simulation file: \(simulationFile)")
        
        let dataDir = Environment.get("DATA_DIR") ?? ""
        let downloadRequest = S3.GetObjectRequest(bucket: bucket, key: simulationFileName)
        
        
        guard let loadedBytes = try? s3.multipartDownload(downloadRequest,
                                                     filename: dataDir + "loadedSimulation.json").wait() else {
            app.logger.error("Error loading file \(simulationFileName)")
            return
        }
        
        app.logger.notice("Succesfully loaded simulation \(loadedBytes) bytes.")
            
        guard let loadedSimulation =  Simulation.load(fileName: "loadedSimulation.json", path: dataDir) else {
            app.logger.error("Error loading simulation")
            return
        }
                
        guard let adminPlayer = loadedSimulation.players.first(where: {$0.isAdmin}) else {
            app.logger.error("Did not find any admin player in loaded simulation. Load failed.")
            return
        }
                
        app.simulation = loadedSimulation
        app.logger.notice("Loaded admin player with username: \(adminPlayer.name), email: \(adminPlayer.emailAddress) and id: \(adminPlayer.id)")
    }
}

/*struct CreateSimulation: LifecycleHandler {
    func willBoot(_ application: Application) throws {
        application.simulation = Simulation(tickCount: 0, gameDate: Date().addingTimeInterval(TimeInterval(SECONDS_IN_YEAR)), nextUpdateDate: Date(), createDefaultAdminPlayer: true)
    }
}*/

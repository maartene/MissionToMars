import Vapor
import Leaf

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
    
 
 // Register middleware (file serving and sessions)
    app.middleware.use(FileMiddleware(publicDirectory: "Public"))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.middleware.use(app.sessions.middleware)
    
    /*
    // Digital Ocean Spaces integration
    if let S3PublicKey = Environment.get("DO_SPACES_ACCESS_KEY"), let S3PrivateKey = Environment.get("DO_SPACES_SECRET") {
        let S3Folder = Environment.get("DO_SPACES_FOLDER") ?? "default"
        let driver = try S3Driver(bucket: "m2m.ams3", host: "digitaloceanspaces.com", accessKey: S3PublicKey, secretKey: S3PrivateKey, region: S3.Region(code: "AMS2"), pathTemplate: "/\(S3Folder)/#folder/#file")
        services.register(driver, as: NetworkDriver.self)

    }
        
    */
    
    //config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}

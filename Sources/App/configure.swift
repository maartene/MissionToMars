import Vapor
import Model
import Leaf
import Storage

/// Called before your application initializes.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#configureswift)
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // Configure LEAF
    try services.register(LeafProvider())
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    // Configure custom tags
    var tags = LeafTagConfig.default()
    tags.use(DateTag(), as: "date")
    tags.use(DecimalTag(), as: "decimal")
    tags.use(ZeroDecimalTag(), as: "dec0")
    tags.use(CashTag(), as: "cash")
    tags.use(ComponentPrereqTag(), as: "compPrereqs")
    tags.use(ImprovementTagTag(), as: "tag")
    tags.use(ImprovementEffectTag(), as: "improvementEffects")
    tags.use(TechnologyUnlocksImprovementsTag(), as: "techUnlocksImprovements")
    tags.use(TechnologyUnlocksTechnologiesTag(), as: "techUnlocksTechnologies")
    tags.use(TechnologyUnlocksComponentsTag(), as: "techUnlocksComponents")
    services.register(tags)

    // Register middleware (file serving and sessions)
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self)
    services.register(middlewares)
    
    // Digital Ocean Spaces integration
    if let S3PublicKey = Environment.get("DO_SPACES_ACCESS_KEY"), let S3PrivateKey = Environment.get("DO_SPACES_SECRET") {
        let S3Folder = Environment.get("DO_SPACES_FOLDER") ?? "default"
        let driver = try S3Driver(bucket: "m2m.ams3", host: "digitaloceanspaces.com", accessKey: S3PublicKey, secretKey: S3PrivateKey, region: S3.Region(code: "AMS2"), pathTemplate: "/\(S3Folder)/#folder/#file")
        services.register(driver, as: NetworkDriver.self)

    }
        
    
    
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}

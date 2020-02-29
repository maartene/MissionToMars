import Vapor
import Model
import FluentSQLite
import Leaf

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
    
    // Configure the rest of your application here
    // Register providers first
    try services.register(FluentSQLiteProvider())
    
    let sqlite: SQLiteDatabase
    if (Environment.get("USE_MEMORY_STORAGE") ?? "disabled") == "enabled" {
        print("Using memory storage.")
        sqlite = try SQLiteDatabase(storage: .memory)
    } else {
        sqlite = try SQLiteDatabase(storage: .file(path: "db.sqlite"))
        print("Database path: \(sqlite.storage)")
    }
    
    /// Register the configured PostgreSQL database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)
    
    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Player.self, database: .sqlite)
    migrations.add(model: Mission.self, database: .sqlite)
    migrations.add(model: Simulation.self, database: .sqlite)
    services.register(migrations)
    
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
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}

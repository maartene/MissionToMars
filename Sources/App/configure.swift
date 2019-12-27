import Vapor
import Model
import FluentPostgreSQL
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
    try services.register(FluentPostgreSQLProvider())
    
    let db_hostname = Environment.get("DB_HOSTNAME") ?? "localhost"
    let db_port = Int(Environment.get("PORT") ?? "5432") ?? 5432
    let db_user = Environment.get("POSTGRES_USER") ?? "vapor"
    let db_password = Environment.get("POSTGRES_PASSWORD")
    let db_db = Environment.get("POSTGRES_DB") ?? "missiontomarsdb"
    
    let psqlConfig: PostgreSQLDatabaseConfig
    if (Environment.get("POSTGRES_TLS") ?? "yes") == "yes" {
        // Configure a PostgreSQL database
        psqlConfig = PostgreSQLDatabaseConfig(hostname: db_hostname, port: db_port, username: db_user, database: db_db, password: db_password, transport: .unverifiedTLS)
    } else {
        // Configure a PostgreSQL database
        psqlConfig = PostgreSQLDatabaseConfig(hostname: db_hostname, port: db_port, username: db_user, database: db_db, password: db_password, transport: .cleartext)
    }
    
    let psql = PostgreSQLDatabase(config: psqlConfig)
    //let sqlite = try SQLiteDatabase(storage: .memory)
    //print("Database path: \(sqlite.storage)")
    
    /// Register the configured PostgreSQL database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: psql, as: .psql)
    services.register(databases)
    
    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Player.self, database: .psql)
    migrations.add(model: Mission.self, database: .psql)
    migrations.add(model: Simulation.self, database: .psql)
    services.register(migrations)
    
    // Configure LEAF
    try services.register(LeafProvider())
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    // Configure custom tags
    var tags = LeafTagConfig.default()
    tags.use(DateTag(), as: "date")
    tags.use(DecimalTag(), as: "decimal")
    tags.use(CashTag(), as: "cash")
    services.register(tags)

    // Register middleware (file serving and sessions)
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self)
    services.register(middlewares)
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}

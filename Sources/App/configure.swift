import Vapor
import Model
import FluentSQLite

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
    
    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .file(path: "db.sqlite"))
    //let sqlite = try SQLiteDatabase(storage: .memory)
    //print("Database path: \(sqlite.storage)")
    
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)
    
    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Player.self, database: .sqlite)
    migrations.add(model: Mission.self, database: .sqlite)
    services.register(migrations)
}

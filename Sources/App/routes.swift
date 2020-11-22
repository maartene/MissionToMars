import Vapor

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ app: Application) throws {
    //try router.register(collection: FrontEndController())
    
    createFrontEndRoutes(app)
    createPasswordResetRoutes(app)
    createManageAccountRoutes(app)
}

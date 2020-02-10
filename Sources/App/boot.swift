import Routing
import Vapor

/// Called after your application has initialized.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#bootswift)
public func boot(_ app: Application) throws {
    // your code here
    
    // this is an ugly hack to get a "Singleton" for the application. 
    FrontEndController.app = app
}

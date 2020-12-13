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
}


/*struct CreateSimulation: LifecycleHandler {
    func willBoot(_ application: Application) throws {
        application.simulation = Simulation(tickCount: 0, gameDate: Date().addingTimeInterval(TimeInterval(SECONDS_IN_YEAR)), nextUpdateDate: Date(), createDefaultAdminPlayer: true)
    }
}*/

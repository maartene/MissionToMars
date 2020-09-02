import App
//import Service
import Vapor
import Foundation

// The contents of main are wrapped in a do/catch block because any errors that get raised to the top level will crash Xcode
do {
    var env = try Environment.detect()
    try LoggingSystem.bootstrap(from: &env)
    
    let app = Application(env)
    defer { app.shutdown() }
    
    try configure(app)
    try app.run()
    
    /*
    try App.configure(&config, &env, &services)
    
    var app: Application?
    var launched = false
    var tryCounter = 0
    
    while launched == false && tryCounter < 20 {
        do {
            app = try Application(
                config: config,
                environment: env,
                services: services
            )
            launched = true
        } catch {
            print(error)
            print("Try \(tryCounter) - trying again in 5 seconds.")
            tryCounter += 1
            sleep(5)
        }
    }
    
    try App.boot(app!)
    
    try app!.run()
     */
} catch {
    print(error)
    exit(1)
}

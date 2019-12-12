import Routing
import Model
import Vapor

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    router.get("testRoute") { req -> Future<Player> in
        let player = Player(username: "testUser")
    
        return player.create(on: req).map(to: Player.self) { player in
            return player
        }
    }
    
    router.get("createCharacter") { req -> Future<View> in
        struct CreateCharacterContext: Codable {
            var errorMessage = "noError"
            var uuid = "unknown"
        }
        
        return Player.createUser(username: "testUser", on: req).flatMap(to: View.self) { result in
            var context = CreateCharacterContext()
            
            switch result {
            case .success(let player):
                context.uuid = String(player.id!)
            case .failure(let error):
                context.errorMessage = error.localizedDescription
                print(context.errorMessage)
            }
            
            return try req.view().render("userCreated", context)
        }
    }
    
    router.get("login", String.parameter) { req -> Future<View> in
        let idString: String = try req.parameters.next()
        guard let id = UUID(idString) else {
            print("\(idString) is not a valid user id")
            throw Abort(.unauthorized)
        }
        
        return Player.find(id, on: req).flatMap(to: View.self) { player in
            guard let player = player else {
                print("Could not find user with id: \(idString)")
                throw Abort(.unauthorized)
            }
            return try req.view().render("main", ["player": player])
        }
    }
    
    router.get() { req in
        return try req.view().render("index")
    }
    
}

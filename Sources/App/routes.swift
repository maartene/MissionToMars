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
    
    router.post("login") { req -> Response in
        let idString: String = (try? req.content.syncGet(at: "playerid")) ?? ""
        
        guard let id = UUID(idString) else {
            print("\(idString) is not a valid user id")
            return req.redirect(to: "/")
        }
        
        try req.session()["playerID"] = idString
        return req.redirect(to: "/main")
    }
    
    router.get("main") { req -> Future<View> in
        struct MainContext: Codable {
            let player: Player
            let mission: Mission?
            let costOfNextTechnologyLevel: Double
        }
        
        guard let id = getPlayerIDFromSession(on: req) else {
            throw Abort(.unauthorized)
        }
        
        return Player.find(id, on: req).flatMap(to: View.self) { player in
            guard let player = player else {
                print("Could not find user with id: \(id)")
                throw Abort(.unauthorized)
            }
            
            // does this player have his/her own mission?
            if let missionID = player.ownsMissionID {
                return try player.getSupportedMission(on: req).flatMap(to: View.self) { mission in
                    guard let mission = mission else {
                        throw Abort(.notFound, reason: "Mission with id \(missionID) does not exist.")
                    }
                    let context = MainContext(player: player, mission: mission, costOfNextTechnologyLevel: player.costOfNextTechnologyLevel)
                    
                    return try req.view().render("main", context)
                }
            }
            
            // this player does not own his/her own mission, perhaps he/she supports the mission of another player?
            else if let supportedPlayerID = player.supportsPlayerID {
                return try player.getSupportedPlayer(on: req).flatMap(to: View.self) { supportedPlayer in
                    guard let supportedPlayer = supportedPlayer else {
                        throw Abort(.notFound, reason: "Player with id\(supportedPlayerID) does not exist.")
                    }
                    
                    return try supportedPlayer.getSupportedMission(on: req).flatMap(to: View.self) { supportedMission in
                        guard let supportedMission = supportedMission else {
                            throw Abort(.notFound, reason: "Mission with id \(supportedPlayer.ownsMissionID) does not exist.")
                        }
                        
                        let context = MainContext(player: player, mission: supportedMission, costOfNextTechnologyLevel: player.costOfNextTechnologyLevel)
                        
                        return try req.view().render("main", context)
                    }
                }
            } else {
                let context = MainContext(player: player, mission: nil, costOfNextTechnologyLevel: player.costOfNextTechnologyLevel)
            
                return try req.view().render("main", context)
            }
        }
    }
    
    router.get("createMission") { req -> Future<Response> in
        let player = Player(username: "foo")
        let newMission = Mission(owningPlayerID: player.id!)
        
        
        return newMission.create(on: req).flatMap(to: Response.self) { mission in
            var changedPlayer = player
            changedPlayer.ownsMissionID = mission.id
            
            return changedPlayer.save(on: req).map(to: Response.self) { player in
                return req.redirect(to: "/main")
            }
        }
    }
    
    router.get("debug", "allUsers") { req -> Future<[Player]> in
        return Player.query(on: req).all()
    }
    
    router.get() { req in
        return try req.view().render("index")
    }
    
    func getPlayerIDFromSession(on req: Request) -> UUID? {
        if let session = try? req.session() {
            if let playerID = session["playerID"] {
                return UUID(playerID)
            }
        }
        return nil
    }
    
}

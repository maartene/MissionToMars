//
//  FrontEndController.swift
//  App
//
//  Created by Maarten Engels on 29/12/2019.
//

import Foundation
import Vapor
import Leaf
import S3

extension Application {
    struct ErrorMessages: StorageKey {
        typealias Value = [UUID: String?]
    }
    
    struct InfoMessages: StorageKey {
        typealias Value = [UUID: String?]
    }
    
    var errorMessages: [UUID: String?] {
        get { guard let messages = self.storage[ErrorMessages.self] else {
                self.storage[InfoMessages.self] = [UUID: String?]()
                return [:]
            }
            return messages
        }
        set { self.storage[ErrorMessages.self] = newValue }
    }
    
    var infoMessages: [UUID: String?] {
        get { guard let messages = self.storage[InfoMessages.self] else {
                self.storage[InfoMessages.self] = [UUID: String?]()
                return [:]
            }
            return messages
        }
        set { self.storage[InfoMessages.self] = newValue }
    }
    
    var simulation: Simulation {
        get { self.storage[Simulation.self]! }
        set { self.storage[Simulation.self] = newValue }
    }
    
    
}

extension Simulation: StorageKey {
    public typealias Value = Simulation
}

struct CreateSimulation: LifecycleHandler {
    func willBoot(_ application: Application) throws {
        application.simulation = Simulation(tickCount: 0, gameDate: Date().addingTimeInterval(TimeInterval(SECONDS_IN_YEAR)), nextUpdateDate: Date(), createDefaultAdminPlayer: true)
    }
}

func createFrontEndRoutes(_ app: Application) {
    
    app.get("create", "player") { req -> EventLoopFuture<View> in
        return req.view.render("createPlayer", ["startingImprovements": Improvement.startImprovements])
        }
        
    app.post("create", "player") { req -> EventLoopFuture<View> in
        struct CreateCharacterContext: Codable {
            var errorMessage = "noError"
            var email = ""
            var uuid = "unknown"
        }
        let emailAddress: String = try req.content.get(at: "emailAddress")
        let name: String = try req.content.get(at: "name")
        let shortNameForm: Int = try req.content.get(at: "startingImprovement")
        guard let startingImprovement = Improvement.ShortName.init(rawValue: shortNameForm) else {
            throw Abort(.badRequest, reason: "Invalid starting improvement shortname \(shortNameForm).")
        }
        
        var context = CreateCharacterContext()
        do {
            let result = try app.simulation.createPlayer(emailAddress: emailAddress, name: name, startImprovementShortName: startingImprovement)
            app.simulation = result.updatedSimulation
            
            context.email = emailAddress
            context.uuid = String(result.newPlayer.id)
            
            sendWelcomeEmail(to: result.newPlayer, on: req)

            return req.view.render("userCreated", context)
        } catch {
            switch error {
            case Simulation.SimulationError.userAlreadyExists:
                context.errorMessage = "A user with email address '\(emailAddress)' already exists. Please choose another one."
            default:
                context.errorMessage = error.localizedDescription
            }
            return req.view.render("userCreated", context)
        }
    }
        
    app.post("login") { req -> Response in
        let idString: String = (try? req.content.get(at: "playerid")) ?? ""
        
        guard UUID(idString) != nil else {
            print("\(idString) is not a valid user id")
            return req.redirect(to: "/")
        }
        
        req.session.data["playerID"] = idString
        if app.simulation.state == .admin {
            return req.redirect(to: "/admin")
        } else {
            return req.redirect(to: "/main")
        }
        
    }
        
    app.get("main") { req in
        return try mainPage(req: req, page: "main")
    }
        
    app.get("mission") { req in
        return try mainPage(req: req, page: "mission")
    }
        
    app.get("technology") { req in
        return try mainPage(req: req, page: "technology")
    }
        
    app.get("improvements") { req in
        return try mainPage(req: req, page: "improvements")
    }
        
    func mainPage(req: Request, page: String) throws -> EventLoopFuture<View> {
        guard let id = getPlayerIDFromSession(on: req) else {
            return req.view.render("index", ["state": app.simulation.state])
        }
        
        /*if simulationIsUpdating {
            self.infoMessages[id] = "Simulation is updating. Thanks for your patience!"
        }*/
        
        if app.simulation.simulationShouldUpdate(currentDate: Date()) {
            let updatedSimulation = app.simulation.updateSimulation(currentDate: Date())
            assert(app.simulation.id == updatedSimulation.id)
            app.simulation = updatedSimulation
    
            // save result (in seperate thread)
            let copy = app.simulation
            let dataDir = Environment.get("DATA_DIR") ?? ""
            do {
                let data = try copy.save(path: dataDir)
                let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
        
                if let accessKey = Environment.get("DO_SPACES_ACCESS_KEY"), let secretKey = Environment.get("DO_SPACES_SECRET") {
                    
                    let s3 = S3(accessKeyId: accessKey, secretAccessKey: secretKey, region: .euwest1, endpoint: "https://m2m.ams3.digitaloceanspaces.com")
                    let uploadRequest = S3.PutObjectRequest(acl: .private, body: data, bucket: bucket, contentLength: Int64(data.count), key: "\(SIMULATION_FILENAME).json")
                    _ = s3.putObject(uploadRequest).map { result in
                        req.logger.info("Save successfull - \(result.eTag ?? "unknown")")
                    }
                } else {
                    req.logger.error("S3 access key and secret key not set in environment. Save failed.")
                }
            } catch {
                req.logger.error("Failed to save simulation due to error: \(error).")
            }
        }
        
        return try getMainViewForPlayer(with: id, simulation: app.simulation, on: req, page: page)
    }
        
    app.get("edit", "mission") { req -> EventLoopFuture<View> in
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        guard let supportedMission = app.simulation.getSupportedMissionForPlayer(player) else {
            throw Abort(.notFound, reason: "No supported mission found for player.")
        }
        
        return req.view.render("editMission", ["missionName": supportedMission.missionName])
    }
        
    app.post("edit", "mission") { req -> Response in
        let newName: String = try req.content.get(at: "missionName")
        
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        if let supportedMission = app.simulation.getSupportedMissionForPlayer(player) {
            var changedMission = supportedMission
            changedMission.missionName = newName
            let updatedSimulation = try app.simulation.replaceMission(changedMission)
            app.simulation = updatedSimulation
        }
        
        return req.redirect(to: "/mission")
    }
        
    app.get("create", "mission") { req -> Response in
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        app.simulation = try app.simulation.createMission(for: player)
        return req.redirect(to: "/mission")
    }
        
    app.get("support", "mission") { req -> EventLoopFuture<View> in
        _ = try getPlayerFromSession(on: req, in: app.simulation)
        
        let unfinishedMissions = app.simulation.missions.filter { mission in mission.missionComplete == false }
        
        let mcs = unfinishedMissions.map { mission -> MissionContext in
            let owningPlayer = app.simulation.players.first(where: { somePlayer in somePlayer.id == mission.owningPlayerID })?.name ?? "unknown"
            return MissionContext(id: mission.id, missionName: mission.missionName, percentageDone: mission.percentageDone, owningPlayerName: owningPlayer)
        }
        
        return req.view.render("missions", ["missions": mcs])
    }
        
    app.get("support", "mission", ":id") { req -> Response in
        guard let supportedMissionID = UUID(req.parameters.get("id") ?? "") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("id") ?? "-") is not a valid GUID.")
        }
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        guard let supportedMission = app.simulation.missions.first(where: {mission in mission.id == supportedMissionID} ) else {
            throw Abort(.notFound, reason: "Could not find mission with id \(supportedMissionID)")
        }
        
        guard supportedMission.missionComplete == false else {
            app.errorMessages[player.id] = "You cannot support a mission that is already complete."
            return req.redirect(to: "/main")
        }
                
        var updatedPlayer = player
                
        updatedPlayer.supportsPlayerID = supportedMission.owningPlayerID
        app.simulation = try app.simulation.replacePlayer(updatedPlayer)
        
        return req.redirect(to: "/mission")
    }
        
    app.get("donate", "to", ":receivingPlayerEmail") { req -> EventLoopFuture<View> in
        struct DonateContext: Content {
            let player: Player
            let receivingPlayerName: String
            let receivingPlayerEmail: String
        }
        
        let receivingPlayerEmail = req.parameters.get("receivingPlayerEmail") ?? ""
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        guard let receivingPlayer = app.simulation.players.first(where: {somePlayer in somePlayer.emailAddress == receivingPlayerEmail}) else {
            throw Abort(.notFound, reason: "Could not find player with emailadress \(receivingPlayerEmail)")
        }
        
        let context = DonateContext(player: player, receivingPlayerName: receivingPlayer.name, receivingPlayerEmail: receivingPlayer.emailAddress)
        return req.view.render("donate", context)
    }
        
    app.get("donate", "to", ":receivingPlayerEmail", "cash", ":donateString") { req -> Response in
        let donatingPlayer = try getPlayerFromSession(on: req, in: app.simulation)
        
        let receivingPlayerEmail = req.parameters.get("receivingPlayerEmail") ?? ""
        let donateString = req.parameters.get("donateString") ?? ""
        
        guard let receivingPlayer = app.simulation.players.first(where: {player in player.emailAddress == receivingPlayerEmail}) else {
            return req.redirect(to: "/")
        }
                
        let cash: Double
        switch donateString {
        case "1k":
            cash = 1_000
        case "10k":
            cash = 10_000
        case "100k":
            cash = 100_000
        case "1m":
            cash = 1_000_000
        case "1b":
            cash = 1_000_000_000
        case "10b":
            cash = 10_000_000_000
        default:
            cash = 0
        }
                
        do {
            let changedSimulation = try app.simulation.donateToPlayerInSameMission(donatingPlayer: donatingPlayer, receivingPlayer: receivingPlayer, cash: cash)
            app.simulation = changedSimulation
            app.infoMessages[donatingPlayer.id] = "You donated $\(Int(cash)) to \(receivingPlayer.name)"
            return req.redirect(to: "/mission")
        } catch {
            if let playerError = error as? Player.PlayerError {
                if playerError == .insufficientFunds {
                    app.errorMessages[donatingPlayer.id] = "Insufficient funds to donate."
                    return req.redirect(to: "/main")
                } else {
                    throw error
                }
            } else {
                throw error
            }
        }
    }
        
    app.get("donate", "to", ":receivingPlayerEmail", "tech", ":tpString") { req -> Response in
        let donatingPlayer = try getPlayerFromSession(on: req, in: app.simulation)
        let receivingPlayerEmail: String = req.parameters.get("receivingPlayerEmail") ?? ""
        guard let techPoints = Int(req.parameters.get("tpString") ?? "") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("tpString") ?? "") is not a valid integer value.")
        }
        
        guard let receivingPlayer = app.simulation.players.first(where: {player in player.emailAddress == receivingPlayerEmail}) else {
            return req.redirect(to: "/")
        }
            
        do {
            let changedSimulation = try app.simulation.donateToPlayerInSameMission(donatingPlayer: donatingPlayer, receivingPlayer: receivingPlayer, techPoints: techPoints)
            app.simulation = changedSimulation
            app.infoMessages[donatingPlayer.id] = "You donated $\(Int(techPoints)) to \(receivingPlayer.name)"
            return req.redirect(to: "/mission")
        } catch {
            if let playerError = error as? Player.PlayerError {
                if playerError == .insufficientTechPoints {
                    app.errorMessages[donatingPlayer.id] = "Insufficient technology points to donate."
                    return req.redirect(to: "/main")
                } else {
                    throw error
                }
            } else {
                throw error
            }
        }
    }
        
    app.get("build", "component", ":shortNameString") { req -> Response in
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        let shortNameString = req.parameters.get("shortNameString") ?? ""
        
        guard let shortName = Component.ShortName.init(rawValue: shortNameString) else {
            throw Abort(.badRequest, reason: "\(shortNameString) is not a valid component shortname.")
        }
        
        guard let component = Component.getComponentByName(shortName) else {
            throw Abort(.notFound, reason: "No component with shortName \(shortName) found.")
        }
        
        do {
            let changedSimulation = try app.simulation.playerInvestsInComponent(player: player, component: component)
            app.simulation = changedSimulation
        } catch {
            switch error {
            case Player.PlayerError.insufficientFunds:
                app.errorMessages[player.id] = "Not enough funds to build component \(component.name)."
            default:
                throw error
            }
        }
        
        
        return req.redirect(to: "/mission")
    }
        
    app.get("advance", "stage") { req -> Response in
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        guard let mission = app.simulation.getSupportedMissionForPlayer(player) else {
            throw Abort(.badRequest, reason: "No mission for player")
        }
        
        let advancedMission = try mission.goToNextStage()
        app.simulation = try app.simulation.replaceMission(advancedMission)
        return req.redirect(to: "/mission")
    }
        
    app.get("build", "improvements") { req -> EventLoopFuture<View> in
        struct ImprovementBuildContext: Codable {
            let player: Player
            let buildPointsPerTick: Double
            let possibleImprovements: [Improvement]
        }
        
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        let possibleImprovements = Improvement.unlockedImprovementsForPlayer(player)
        let context = ImprovementBuildContext(player: player, buildPointsPerTick: player.buildPointsPerTick, possibleImprovements: possibleImprovements)
        
        return req.view.render("improvements", context)
    }
        
    app.get("build", "improvements", ":number") { req -> Response in
        guard let number = Int(req.parameters.get("number") ?? "") else {
            throw Abort (.badRequest, reason: "\(req.parameters.get("number") ?? "") is not a valid Integer.")
        }
        
        guard let shortName = Improvement.ShortName(rawValue: number) else {
            return req.redirect(to: "/main")
        }
        
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        guard let improvement = Improvement.getImprovementByName(shortName) else {
            app.errorMessages[player.id] = "No improvement with shortName \(shortName) found."
            return req.redirect(to: "/main")
        }
        
        do {
            
            let buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
            app.simulation = try app.simulation.replacePlayer(buildingPlayer)
            return req.redirect(to: "/improvements")
        } catch {
            switch error {
            case Player.PlayerError.insufficientImprovementSlots:
                app.errorMessages[player.id] = "You can have a maximum of \(player.improvementSlotsCount) improvements."
            case Player.PlayerError.insufficientFunds:
                app.errorMessages[player.id] = "Insufficient funds to build \(improvement.name)."
                return req.redirect(to: "/main")
            case Player.PlayerError.playerIsAlreadyBuildingImprovement:
                app.errorMessages[player.id] = "You can't build \(improvement.name) while you are building \(player.currentlyBuildingImprovement?.name ?? "unknown")"
                return req.redirect(to: "/main")
            default:
                throw error
            }
            return req.redirect(to: "/main")
        }
    }
        
    app.get("rush", "improvements", ":number") { req -> Response in
        guard let number =  Int(req.parameters.get("number") ?? "") else {
            throw Abort (.badRequest, reason: "\(req.parameters.get("number") ?? "") is not a valid Integer.")
        }
        
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        guard (0 ..< player.improvements.count).contains(number) else {
            app.logger.error("/rush/improvements/:number - number \(number) out of bounds.")
            return req.redirect(to: "/main")
        }
            
        let improvement = player.improvements[number]
        
        do {
            let rushingPlayer = try player.rushImprovement(in: number)
            app.simulation = try app.simulation.replacePlayer(rushingPlayer)
            app.infoMessages[rushingPlayer.id] = "Succesfully rushed \(improvement.name)."
            return req.redirect(to: "/improvements")
        } catch {
            switch error {
            case Player.PlayerError.insufficientFunds:
                app.errorMessages[player.id] = "Insufficient funds to rush \(improvement.name)."
                return req.redirect(to: "/main")
            case Improvement.ImprovementError.improvementCannotBeRushed:
                app.errorMessages[player.id] = "\(improvement.name) cannot be rushed."
                return req.redirect(to: "/main")
            default:
                app.errorMessages[player.id] = error.localizedDescription
                return req.redirect(to: "/main")
            }
            //return Future.map(on: req) { return req.redirect(to: "/main") }
        }
    }
        
    app.get("sell", "improvement", ":number") { req -> Response in
        guard let number = Int(req.parameters.get("number") ?? "") else {
            throw Abort (.badRequest, reason: "\(req.parameters.get("number") ?? "") is not a valid Integer.")
        }
        
        guard let shortName = Improvement.ShortName(rawValue: number) else {
            return req.redirect(to: "/main")
        }
        
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        guard let improvement = Improvement.getImprovementByName(shortName) else {
            app.errorMessages[player.id] = "No improvement with shortName \(shortName) found."
            return req.redirect(to: "/main")
        }
        
        do {
            let sellingPlayer = try player.sellImprovement(improvement)
            app.simulation = try app.simulation.replacePlayer(sellingPlayer)
            app.infoMessages[sellingPlayer.id] = "Succesfully sold \(improvement.name)."
            return req.redirect(to: "/improvements")
        } catch {
            switch error {
            case Improvement.ImprovementError.improvementIncomplete:
                app.errorMessages[player.id] = "You can only sell completed improvements."
                return req.redirect(to: "/main")
            default:
                app.errorMessages[player.id] = error.localizedDescription
                return req.redirect(to: "/main")
            }
        }
    }
    
    app.get("trigger", "improvements", ":number") { req -> Response in
        guard let number =  Int(req.parameters.get("number") ?? "") else {
            throw Abort (.badRequest, reason: "\(req.parameters.get("number") ?? "") is not a valid Integer.")
        }
        
        /*guard let shortName = Improvement.ShortName(rawValue: number) else {
            return req.redirect(to: "/main")
        }
        
        guard let improvement = Improvement.getImprovementByName(shortName) else {
            return req.redirect(to: "/main")
        }
        
        
        
        guard let index = player.improvements.firstIndex(where: { $0.shortName == shortName }) else {
            app.errorMessages[player.id] = "Player does not have \(improvement.name)."
            return req.redirect(to: "/main")
        }*/
        
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        guard (0 ..< player.improvements.count).contains(number) else {
            app.logger.error("/trigger/improvements/:number Index \(number) out of bounds.")
            return req.redirect(to: "/main")
        }
        
        let improvement = player.improvements[number]
        
        do {
            let triggeringPlayer = try player.triggerImprovement(number)
            app.simulation = try app.simulation.replacePlayer(triggeringPlayer)
            app.infoMessages[triggeringPlayer.id] = "Succesfully triggered \(improvement.name)."
            return req.redirect(to: "/improvements")
        } catch {
            switch error {
            case Player.PlayerError.insufficientActionPoints:
                app.errorMessages[player.id] = "You don't have enough Actions Points (\(player.actionPoints)) for this action."
            default:
                app.errorMessages[player.id] = error.localizedDescription
            }
            return req.redirect(to: "/main")
        }
    }
        
    app.get("mission", "supportingPlayers") { req -> EventLoopFuture<View> in
        struct SupportingPlayerContext: Content {
            let player: Player
            let supportingPlayers: [Player]
            let mission: Mission
        }
        
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        guard let mission = app.simulation.getSupportedMissionForPlayer(player) else {
            throw Abort(.notFound, reason: "Mission not found for player.")
        }
        
        let supportingPlayers = try app.simulation.supportingPlayersForMission(mission)
        
        let context = SupportingPlayerContext(player: player, supportingPlayers: supportingPlayers, mission: mission)
        return req.view.render("mission_supportingPlayers", context)
    }
        
    app.get("unlock", "technologies") { req -> EventLoopFuture<View> in
        struct UnlockTechnologyContext: Codable {
            let player: Player
            let possibleTechnologies: [Technology]
        }
        
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        let possibleTechnologies = Technology.unlockableTechnologiesForPlayer(player)
        let context = UnlockTechnologyContext(player: player, possibleTechnologies: possibleTechnologies)
        
        return req.view.render("technologies", context)
    }
        
    app.get("unlock", "technologies", ":number") { req -> Response in
        guard let number = Int(req.parameters.get("number") ?? "") else {
            throw Abort (.badRequest, reason: "\(req.parameters.get("number") ?? "") is not a valid Integer.")
        }
        
        guard let shortName = Technology.ShortName(rawValue: number) else {
            return req.redirect(to: "/main")
        }
        
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        
        guard let technology = Technology.getTechnologyByName(shortName) else {
            app.errorMessages[player.id] = "No technology with shortName \(shortName) found."
            return req.redirect(to: "/main")
        }
        
        do {
            
            let unlockingPlayer = try player.investInTechnology(technology)
            app.simulation = try app.simulation.replacePlayer(unlockingPlayer)
            app.infoMessages[unlockingPlayer.id] = "Succesfully unlocked \(technology.name)."
            return req.redirect(to: "/technology")
        } catch {
            switch error {
            case Player.PlayerError.playerAlreadyUnlockedTechnology:
                app.errorMessages[player.id] = "You already unlocked \(technology.name)."
            case Player.PlayerError.insufficientTechPoints:
                app.errorMessages[player.id] = "Insufficient technology points to unlock \(technology.name)."
            case Player.PlayerError.playerMissesPrerequisiteTechnology:
                app.errorMessages[player.id] = "You miss the prerequisite technology to unlock \(technology.name)."
            default:
                throw error
            }
            return req.redirect(to: "/main")
        }
    }
        
    app.get("admin") { req -> EventLoopFuture<View> in
        struct FileInfo: Content {
            let fileName: String
            let creationDate: String
            let modifiedDate: String
            let isCurrentSimulation: Bool
        }
        
        struct PlayerInfo: Content {
            let name: String
            let email: String
            let isAdmin: Bool
        }
        
        struct AdminContext: Content {
            let player: Player
            //let backupFiles: [FileInfo]
            let infoMessage: String?
            let errorMessage: String?
            let state: Simulation.SimulationState
            let players: [PlayerInfo]
        }
        
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        let players = app.simulation.players.map { player in
            PlayerInfo(name: player.name, email: player.emailAddress, isAdmin: player.isAdmin)
        }
        
        let context = AdminContext(player: player,
                                   //backupFiles: sortedFiles,
                                   infoMessage: app.infoMessages[player.id] ?? nil, errorMessage: app.errorMessages[player.id] ?? nil, state: app.simulation.state, players: players)
        return req.view.render("admin/admin", context)
    }
        
    app.get("admin", "leaveAdminMode") { req -> Response in
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard app.simulation.state == .admin else {
            throw Abort(.badRequest, reason: "Can only leave admin mode when simulation is in admin mode.")
        }
        
        app.simulation.state = .running
        return req.redirect(to: "/admin")
    }
        
    app.get("admin", "save") { req -> EventLoopFuture<Response> in
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        let dataDir = Environment.get("DATA_DIR") ?? ""
        let data = try app.simulation.save(fileName: "\(SIMULATION_FILENAME).json", path: dataDir)
        let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
        
        guard let accessKey = Environment.get("DO_SPACES_ACCESS_KEY"), let secretKey = Environment.get("DO_SPACES_SECRET") else {
            app.errorMessages[player.id] = "S3 access key and secret key not set in environment. Save failed."
            let promise = req.eventLoop.makePromise(of: Response.self)
            promise.succeed(req.redirect(to: "/admin"))
            return promise.futureResult
        }
        
        let s3 = S3(accessKeyId: accessKey, secretAccessKey: secretKey, region: .euwest1, endpoint: "https://m2m.ams3.digitaloceanspaces.com")
        let uploadRequest = S3.PutObjectRequest(acl: .private, body: data, bucket: bucket, contentLength: Int64(data.count), key: "\(SIMULATION_FILENAME).json")
        return s3.putObject(uploadRequest).map { result in
            app.infoMessages[player.id] = "Save succesfull. (\(result.eTag ?? "unknown"))"
            return req.redirect(to: "/admin")
        }
        
        
        //let promise = req.eventLoop.makePromise(of: Response.self)
        //promise.succeed(req.redirect(to: "/admin"))
        //return promise.futureResult
        /*return try Storage.upload(bytes: data, fileName: "simulation", fileExtension: "json", folder: "data", on: req).map(to: Response.self) { result in
            self.infoMessages[player.id] = "Save successfull"
            return req.redirect(to: "/admin")
        }*/
    }
        
    app.get("admin", "enterAdminMode") { req -> Response in
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard app.simulation.state != .admin else {
            throw Abort(.badRequest, reason: "Can only enter admin mode when simulation is not already in admin mode.")
        }
        
        print("entering admin mode.")
        app.simulation.state = .admin
        return req.redirect(to: "/admin")
    }
        
    app.get("admin", "bless", ":userName") { req -> Response in
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard let playerToBlessName = req.parameters.get("userName") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("userName") ?? "unknown") is not a valid string value.")
        }
        
        guard let playerToBless = app.simulation.players.first(where: {$0.name == playerToBlessName }) else {
            throw Abort(.notFound, reason: "Could not find player with name \(playerToBlessName).")
        }
        
        let blessedPlayer = playerToBless.bless()
        app.simulation = try app.simulation.replacePlayer(blessedPlayer)
        return req.redirect(to: "/admin")
    }
        
    app.get("admin", "load") { req -> EventLoopFuture<Response> in
        let player = try getPlayerFromSession(on: req, in: app.simulation)
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard app.simulation.state == .admin else {
            throw Abort(.badRequest, reason: "Loading of database is only allowed in 'Admin' state.")
        }
        
        let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
        
        guard let accessKey = Environment.get("DO_SPACES_ACCESS_KEY"), let secretKey = Environment.get("DO_SPACES_SECRET") else {
            req.logger.error("S3 access key and secret key not set in environment. Save failed.")
            let promise = req.eventLoop.makePromise(of: Response.self)
            promise.succeed(req.redirect(to: "/admin"))
            return promise.futureResult
        }
        
        let s3 = S3(accessKeyId: accessKey, secretAccessKey: secretKey, region: .euwest1, endpoint: "https://m2m.ams3.digitaloceanspaces.com")
        let downloadRequest = S3.GetObjectRequest(bucket: bucket, key: "\(SIMULATION_FILENAME).json")
        return s3.getObject(downloadRequest).map { response in
            guard let data = response.body else {
                app.errorMessages[player.id] = "Received empty/no response. Load failed."
                return req.redirect(to: "/admin")
            }
            
            let decoder = JSONDecoder()
            do {
                let loadedSimulation = try decoder.decode(Simulation.self, from: data)
                guard let adminPlayer = loadedSimulation.players.first(where: {$0.isAdmin}) else {
                    app.errorMessages[player.id] = "Did not find any admin player in loaded simulation. Load failed."
                    return req.redirect(to: "/admin")
                }
                req.logger.notice("Loaded admin player with username: \(adminPlayer.name), email: \(adminPlayer.emailAddress) and id: \(adminPlayer.id)")
                app.simulation = loadedSimulation
                return req.redirect(to: "/")
            } catch {
                
                req.logger.error("Load failed: \(error)")
                return req.redirect(to: "/admin")
            }
            
        }
    }
        
        
    app.get("debug", "allUsers") { req -> [Player] in
        guard (Environment.get("DEBUG_MODE") ?? "inactive") == "active" else {
            throw Abort(.notFound)
        }
        return app.simulation.players
    }
    
    app.post("debug", "cash") { req -> [Player] in
        guard (Environment.get("DEBUG_MODE") ?? "inactive") == "active" else {
            throw Abort(.notFound)
        }
        
        let richPlayers = app.simulation.players.map { player -> Player in
            var changedPlayer = player
            changedPlayer.debug_setCash(4_000_000_000)
            return changedPlayer
        }
        
        for player in richPlayers {
            app.simulation = try app.simulation.replacePlayer(player)
        }
        return app.simulation.players
    }
    
    app.post("debug", "tech") { req -> [Player] in
        guard (Environment.get("DEBUG_MODE") ?? "inactive") == "active" else {
            throw Abort(.notFound)
        }
        
        let smartPlayers = app.simulation.players.map { player -> Player in
            var changedPlayer = player
            changedPlayer.debug_setTech(2_000)
            return changedPlayer
        }
        
        for player in smartPlayers {
            app.simulation = try app.simulation.replacePlayer(player)
        }
        return app.simulation.players
    }
        
    app.post("debug", "createDummyUsers") { req -> [Player] in
        guard (Environment.get("DEBUG_MODE") ?? "inactive") == "active" else {
            throw Abort(.notFound)
        }
        
        for i in 0 ..< 1_000 {
            let result = try app.simulation.createPlayer(emailAddress: "dummyUser\(i)\(Int.random(in: 0...1_000_000))@example.com", name: "dummyUser\(i)\(Int.random(in: 0...1_000_000))")
            app.simulation = result.updatedSimulation
        }
        return app.simulation.players
    }
        
        /*router.get("debug", "getFileIndex") { req in
            return try Storage.get(path: "/local/data/", on: req)
        }*/
        
    app.get() { req in
        return req.view.render("index", ["state": app.simulation.state])
    }
        
    app.get("debug", "dataDump") { req -> String in
        guard (Environment.get("DEBUG_MODE") ?? "inactive") == "active" else {
            throw Abort(.notFound)
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(app.simulation)
            return String(data: data, encoding: .utf8) ?? "empty"
        } catch {
            print(error)
            return("Error while backup up: \(error).")
        }
    }
            
    func getPlayerIDFromSession(on req: Request) -> UUID? {
        if req.hasSession, let playerID = req.session.data["playerID"] {
            return UUID(playerID)
        }
        return nil
    }
    
    func getMainViewForPlayer(with id: UUID, simulation: Simulation, on req: Request, page: String = "main") throws -> EventLoopFuture<View> {
        struct ImprovementContext: Codable {
            let slot: Int
            let improvement: Improvement
        }
        
        struct MainContext: Codable {
            let player: Player
            let mission: Mission?
            let currentStage: Stage?
            let currentBuildingComponents: [Component]
            let simulation: Simulation
            let errorMessage: String?
            let infoMessage: String?
            let currentStageComplete: Bool
            let unlockableTechnologogies: [Technology]
            let unlockedTechnologies: [Technology]
            let unlockedComponents: [Component]
            let techlockedComponents: [Component]
            let playerIsBuildingComponent: Bool
            let cashPerDay: Double
            let techPerDay: Double
            let componentBuildPointsPerDay: Double
            let page: String
            let simulationIsUpdating: Bool
            let improvements: [ImprovementContext]
            let maxActionPoints: Int
        }
        
        guard let player = app.simulation.players.first(where: {somePlayer in somePlayer.id == id}) else {
            print("Could not find user with id: \(id)")
            return req.view.render("index")
        }
        
        var errorMessages = app.errorMessages
        let errorMessage = errorMessages[id] ?? nil
        errorMessages.removeValue(forKey: id)
        app.errorMessages = errorMessages
        
        var infoMessages = app.infoMessages
        let infoMessage = app.infoMessages[id] ?? nil
        infoMessages.removeValue(forKey: id)
        app.infoMessages = infoMessages
 
        var improvements = [ImprovementContext]()
        for i in 0 ..< player.improvements.count {
            improvements.append(ImprovementContext(slot: i, improvement: player.improvements[i]))
        }
        
        if let mission = app.simulation.getSupportedMissionForPlayer(player) {
            if mission.missionComplete {
                return req.view.render("win")
            }
            
            var unlockedComponents = [Component]()
            var techlockedComponents = [Component]()
            
            for component in mission.currentStage.components {
                if component.playerHasPrerequisitesForComponent(player) {
                    unlockedComponents.append(component)
                } else {
                    techlockedComponents.append(component)
                }
            }
            
            let context = MainContext(player: player, mission: mission, currentStage: mission.currentStage, currentBuildingComponents: mission.currentStage.currentlyBuildingComponents, simulation: simulation, errorMessage: errorMessage, infoMessage: infoMessage, currentStageComplete: mission.currentStage.stageComplete, unlockableTechnologogies: Technology.unlockableTechnologiesForPlayer(player), unlockedTechnologies: player.unlockedTechnologies, unlockedComponents: unlockedComponents, techlockedComponents: techlockedComponents, playerIsBuildingComponent: mission.currentStage.playerIsBuildingComponentInStage(player), cashPerDay: player.cashPerTick, techPerDay: player.techPerTick, componentBuildPointsPerDay: player.componentBuildPointsPerTick,  page: page, simulationIsUpdating: false, improvements: improvements, maxActionPoints: player.maxActionPoints)
            
            return req.view.render("main_\(page)", context)
        } else {
            // no mission
            let context = MainContext(player: player, mission: nil, currentStage: nil, currentBuildingComponents: [], simulation: simulation, errorMessage: errorMessage, infoMessage: infoMessage,  currentStageComplete: false, unlockableTechnologogies: Technology.unlockableTechnologiesForPlayer(player), unlockedTechnologies: player.unlockedTechnologies, unlockedComponents: [], techlockedComponents: [], playerIsBuildingComponent: false, cashPerDay: player.cashPerTick, techPerDay: player.techPerTick, componentBuildPointsPerDay: player.componentBuildPointsPerTick, page: page, simulationIsUpdating: false, improvements: improvements, maxActionPoints: player.maxActionPoints)
            
            return req.view.render("main_\(page)", context)
        }
    }
    
    func getPlayerFromSession(on req: Request, in simulation: Simulation) throws -> Player {
        guard let id = getPlayerIDFromSession(on: req) else {
            throw Abort(.unauthorized)
        }
        
        guard let player = simulation.players.first(where: {player in player.id == id }) else {
            throw Abort(.unauthorized)
        }
        
        return player
    }
    
    func sendWelcomeEmail(to player: Player, on container: Request) {
        if let publicKey = Environment.get("MAILJET_API_KEY"), let privateKey = Environment.get("MAILJET_SECRET_KEY") {
        
        let mailJetConfig = MailJetConfig(apiKey: publicKey, secretKey: privateKey, senderName: "Mission2Mars Support", senderEmail: "support@mission2mars.space")
        mailJetConfig.sendMessage(to: player.emailAddress, toName: player.name, subject: "Your login id", message: """
            Welcome \(player.name) to Mission2Mars
            
            Your login id is: \(player.id)
            Please keep this code secret, as there is no other authentication method at this time!
            
            Have fun!
            
            - the Mission2Mars team
            Sent from: \(Environment.get("ENVIRONMENT") ?? "local test")
            """, htmlMessage: """
            <h1>Welcome \(player.name) to Mission2Mars</h1>
            
            <h3>Your login id is: <b>\(player.id)</b></h3>
            <p>Please keep this code secret, as there is no other authentication method at this time!</p>
            <p>&nbsp;</p>
            <p>Have fun!</p>
            <p>&nbsp;</p>
            <p>- the Mission2Mars team</p>
            <p>Sent from: \(Environment.get("ENVIRONMENT") ?? "unknown")</p>
            """, on: container)
        }
    }
}

struct MissionContext: Content {
    let id: UUID
    let missionName: String
    let percentageDone: Double
    let owningPlayerName: String
}

//
//  FrontEndController.swift
//  App
//
//  Created by Maarten Engels on 29/12/2019.
//

import Foundation
import Vapor
import Leaf
import Model
import MailJet
import Storage

class FrontEndController: RouteCollection {
    
    var errorMessages = [UUID: String?]()
    var infoMessages = [UUID: String?]()
    var simulation: Simulation
    var simulationIsUpdating = false
    
    let queue = OperationQueue()
    
    init() {
        let dataDir = Environment.get("DATA_DIR") ?? ""
        if let loadedSimulation = Simulation.load(path: dataDir) {
            simulation = loadedSimulation
        } else {
            print("Could not load simulation, generating a new one.")
            simulation = Simulation(tickCount: 0, gameDate: Date().addingTimeInterval(TimeInterval(SECONDS_IN_YEAR)), nextUpdateDate: Date())
        }
    }
    
    func boot(router: Router) throws {
        router.get("create/player") { req -> Future<View> in
            return try req.view().render("createPlayer", ["startingImprovements": Improvement.startImprovements])
        }
        
        router.post("create/player") { req -> Future<View> in
            struct CreateCharacterContext: Codable {
                var errorMessage = "noError"
                var email = ""
                var uuid = "unknown"
            }
            let emailAddress: String = try req.content.syncGet(at: "emailAddress")
            let name: String = try req.content.syncGet(at: "name")
            let shortNameForm: Int = try req.content.syncGet(at: "startingImprovement")
            guard let startingImprovement = Improvement.ShortName.init(rawValue: shortNameForm) else {
                throw Abort(.badRequest, reason: "Invalid starting improvement shortname \(shortNameForm).")
            }
            
            var context = CreateCharacterContext()
            do {
                let result = try self.simulation.createPlayer(emailAddress: emailAddress, name: name, startImprovementShortName: startingImprovement)
                self.simulation = result.updatedSimulation
                
                context.email = emailAddress
                context.uuid = String(result.newPlayer.id)
                
                self.sendWelcomeEmail(to: result.newPlayer, on: req)

                return try req.view().render("userCreated", context)
            } catch {
                switch error {
                case Simulation.SimulationError.userAlreadyExists:
                    context.errorMessage = "A user with email address '\(emailAddress)' already exists. Please choose another one."
                default:
                    context.errorMessage = error.localizedDescription
                }
                return try req.view().render("userCreated", context)
            }
        }
        
        router.post("login") { req -> Response in
            let idString: String = (try? req.content.syncGet(at: "playerid")) ?? ""
            
            guard UUID(idString) != nil else {
                print("\(idString) is not a valid user id")
                return req.redirect(to: "/")
            }
            
            try req.session()["playerID"] = idString
            return req.redirect(to: "/main")
        }
        
        router.get("main") { req in
            return try mainPage(req: req, page: "main")
        }
        
        router.get("mission") { req in
            return try mainPage(req: req, page: "mission")
        }
        
        router.get("technology") { req in
            return try mainPage(req: req, page: "technology")
        }
        
        router.get("improvements") { req in
            return try mainPage(req: req, page: "improvements")
        }
        
        
        func mainPage(req: Request, page: String) throws -> Future<View> {
            guard let id = self.getPlayerIDFromSession(on: req) else {
                return try req.view().render("index")
            }
            
            if simulationIsUpdating {
                self.infoMessages[id] = "Simulation is updating. Thanks for your patience!"
            }
            
            if simulation.simulationShouldUpdate(currentDate: Date()) && self.simulationIsUpdating == false {
                simulationIsUpdating = true
                let updatedSimulation = simulation.updateSimulation(currentDate: Date())
                assert(simulation.id == updatedSimulation.id)
                self.simulation = updatedSimulation
        
                // save result (in seperate thread)
                let copy = self.simulation
                queue.addOperation {
                    let dataDir = Environment.get("DATA_DIR") ?? ""
                    do {
                        try copy.save(path: dataDir)
                    } catch {
                        print("failed to save simulation")
                    }
                }
                
                simulationIsUpdating = false
            }
            
            return try self.getMainViewForPlayer(with: id, simulation: simulation, on: req, page: page)
        }
        
        router.get("edit/mission") { req -> Future<View> in
            let player = try self.getPlayerFromSession(on: req)
            
            guard let supportedMission = self.simulation.getSupportedMissionForPlayer(player) else {
                throw Abort(.notFound, reason: "No supported mission found for player.")
            }
            
            return try req.view().render("editMission", ["missionName": supportedMission.missionName])
        }
        
        router.post("edit/mission") { req -> Response in
            let newName: String = try req.content.syncGet(at: "missionName")
            
            let player = try self.getPlayerFromSession(on: req)
            
            if let supportedMission = self.simulation.getSupportedMissionForPlayer(player) {
                var changedMission = supportedMission
                changedMission.missionName = newName
                let updatedSimulation = try self.simulation.replaceMission(changedMission)
                self.simulation = updatedSimulation
            }
            
            return req.redirect(to: "/mission")
        }
        
        router.get("create/mission") { req -> Response in
            let player = try self.getPlayerFromSession(on: req)
            self.simulation = try self.simulation.createMission(for: player)
            return req.redirect(to: "/mission")
        }
        
        router.get("support/mission") { req -> Future<View> in
            _ = try self.getPlayerFromSession(on: req)
            
            let unfinishedMissions = self.simulation.missions.filter { mission in mission.missionComplete == false }
            
            let mcs = unfinishedMissions.map { mission -> MissionContext in
                let owningPlayer = self.simulation.players.first(where: { somePlayer in somePlayer.id == mission.owningPlayerID })?.name ?? "unknown"
                return MissionContext(id: mission.id, missionName: mission.missionName, percentageDone: mission.percentageDone, owningPlayerName: owningPlayer)
            }
            
            return try req.view().render("missions", ["missions": mcs])
        }
        
        router.get("support/mission", UUID.parameter) { req -> Response in
            let supportedMissionID: UUID = try req.parameters.next()
            let player = try self.getPlayerFromSession(on: req)
            
            guard let supportedMission = self.simulation.missions.first(where: {mission in mission.id == supportedMissionID} ) else {
                throw Abort(.notFound, reason: "Could not find mission with id \(supportedMissionID)")
            }
            
            guard supportedMission.missionComplete == false else {
                self.errorMessages[player.id] = "You cannot support a mission that is already complete."
                return req.redirect(to: "/main")
            }
                    
            var updatedPlayer = player
                    
            updatedPlayer.supportsPlayerID = supportedMission.owningPlayerID
            self.simulation = try self.simulation.replacePlayer(updatedPlayer)
            
            return req.redirect(to: "/mission")
        }
        
        router.get("donate/to", String.parameter) { req -> Future<View> in
            struct DonateContext: Content {
                let player: Player
                let receivingPlayerName: String
                let receivingPlayerEmail: String
            }
            
            let receivingPlayerEmail: String = try req.parameters.next()
            let player = try self.getPlayerFromSession(on: req)
            
            guard let receivingPlayer = self.simulation.players.first(where: {somePlayer in somePlayer.emailAddress == receivingPlayerEmail}) else {
                throw Abort(.notFound, reason: "Could not find player with emailadress \(receivingPlayerEmail)")
            }
            
            let context = DonateContext(player: player, receivingPlayerName: receivingPlayer.name, receivingPlayerEmail: receivingPlayer.emailAddress)
            return try req.view().render("donate", context)
        }
        
        router.get("donate/to", String.parameter, "cash", String.parameter) { req -> Response in
            let donatingPlayer = try self.getPlayerFromSession(on: req)
            
            let receivingPlayerEmail: String = try req.parameters.next()
            let donateString: String = try req.parameters.next()
            
            guard let receivingPlayer = self.simulation.players.first(where: {player in player.emailAddress == receivingPlayerEmail}) else {
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
                let changedSimulation = try self.simulation.donateToPlayerInSameMission(donatingPlayer: donatingPlayer, receivingPlayer: receivingPlayer, cash: cash)
                self.simulation = changedSimulation
                self.infoMessages[donatingPlayer.id] = "You donated $\(Int(cash)) to \(receivingPlayer.name)"
                return req.redirect(to: "/mission")
            } catch {
                if let playerError = error as? Player.PlayerError {
                    if playerError == .insufficientFunds {
                        self.errorMessages[donatingPlayer.id] = "Insufficient funds to donate."
                        return req.redirect(to: "/main")
                    } else {
                        throw error
                    }
                } else {
                    throw error
                }
            }
        }
        
        router.get("donate/to", String.parameter, "tech", Int.parameter) { req -> Response in
            let donatingPlayer = try self.getPlayerFromSession(on: req)
            let receivingPlayerEmail: String = try req.parameters.next()
            let techPoints: Int = try req.parameters.next()
            
            guard let receivingPlayer = self.simulation.players.first(where: {player in player.emailAddress == receivingPlayerEmail}) else {
                return req.redirect(to: "/")
            }
                
            do {
                let changedSimulation = try self.simulation.donateToPlayerInSameMission(donatingPlayer: donatingPlayer, receivingPlayer: receivingPlayer, techPoints: techPoints)
                self.simulation = changedSimulation
                self.infoMessages[donatingPlayer.id] = "You donated $\(Int(techPoints)) to \(receivingPlayer.name)"
                return req.redirect(to: "/mission")
            } catch {
                if let playerError = error as? Player.PlayerError {
                    if playerError == .insufficientTechPoints {
                        self.errorMessages[donatingPlayer.id] = "Insufficient technology points to donate."
                        return req.redirect(to: "/main")
                    } else {
                        throw error
                    }
                } else {
                    throw error
                }
            }
        }
        
        router.get("build/component", String.parameter) { req -> Response in
            let player = try self.getPlayerFromSession(on: req)
            let shortNameString: String = try req.parameters.next()
            
            guard let shortName = Component.ShortName.init(rawValue: shortNameString) else {
                throw Abort(.badRequest, reason: "\(shortNameString) is not a valid component shortname.")
            }
            
            guard let component = Component.getComponentByName(shortName) else {
                throw Abort(.notFound, reason: "No component with shortName \(shortName) found.")
            }
            
            do {
                let changedSimulation = try self.simulation.playerInvestsInComponent(player: player, component: component)
                self.simulation = changedSimulation
            } catch {
                switch error {
                case Player.PlayerError.insufficientFunds:
                    self.errorMessages[player.id] = "Not enough funds to build component \(component.name)."
                default:
                    throw error
                }
            }
            
            
            return req.redirect(to: "/mission")
        }
        
        router.get("advance/stage") { req -> Response in
            let player = try self.getPlayerFromSession(on: req)
            guard let mission = self.simulation.getSupportedMissionForPlayer(player) else {
                throw Abort(.badRequest, reason: "No mission for player")
            }
            
            let advancedMission = try mission.goToNextStage()
            self.simulation = try self.simulation.replaceMission(advancedMission)
            return req.redirect(to: "/mission")
        }
        
        router.get("build/improvements") { req -> Future<View> in
            struct ImprovementBuildContext: Codable {
                let player: Player
                let buildPointsPerTick: Double
                let possibleImprovements: [Improvement]
            }
            
            let player = try self.getPlayerFromSession(on: req)
            
            let possibleImprovements = Improvement.unlockedImprovementsForPlayer(player)
            let context = ImprovementBuildContext(player: player, buildPointsPerTick: player.buildPointsPerTick, possibleImprovements: possibleImprovements)
            
            return try req.view().render("improvements", context)
        }
        
        router.get("build/improvements", Int.parameter) { req -> Response in
            let number: Int = try req.parameters.next()
            
            guard let shortName = Improvement.ShortName(rawValue: number) else {
                return req.redirect(to: "/main")
            }
            
            let player = try self.getPlayerFromSession(on: req)
            
            guard let improvement = Improvement.getImprovementByName(shortName) else {
                self.errorMessages[player.id] = "No improvement with shortName \(shortName) found."
                return req.redirect(to: "/main")
            }
            
            do {
                
                let buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
                self.simulation = try self.simulation.replacePlayer(buildingPlayer)
                return req.redirect(to: "/improvements")
            } catch {
                switch error {
                case Player.PlayerError.insufficientImprovementSlots:
                    self.errorMessages[player.id] = "You can have a maximum of \(player.improvementSlotsCount) improvements."
                case Player.PlayerError.insufficientFunds:
                    self.errorMessages[player.id] = "Insufficient funds to build \(improvement.name)."
                    return req.redirect(to: "/main")
                case Player.PlayerError.playerIsAlreadyBuildingImprovement:
                    self.errorMessages[player.id] = "You can't build \(improvement.name) while you are building \(player.currentlyBuildingImprovement?.name ?? "unknown")"
                    return req.redirect(to: "/main")
                default:
                    throw error
                }
                return req.redirect(to: "/main")
            }
        }
        
        router.get("rush/improvements", Int.parameter) { req -> Response in
            let number: Int = try req.parameters.next()
            
            guard let shortName = Improvement.ShortName(rawValue: number) else {
                return req.redirect(to: "/main")
            }
            
            let player = try self.getPlayerFromSession(on: req)
            
            guard let improvement = Improvement.getImprovementByName(shortName) else {
                self.errorMessages[player.id] = "No improvement with shortName \(shortName) found."
                return req.redirect(to: "/main")
            }
            
            do {
                let rushingPlayer = try player.rushImprovement(improvement)
                self.simulation = try self.simulation.replacePlayer(rushingPlayer)
                self.infoMessages[rushingPlayer.id] = "Succesfully rushed \(improvement.name)."
                return req.redirect(to: "/improvements")
            } catch {
                switch error {
                case Player.PlayerError.insufficientFunds:
                    self.errorMessages[player.id] = "Insufficient funds to rush \(improvement.name)."
                    return req.redirect(to: "/main")
                case Improvement.ImprovementError.improvementCannotBeRushed:
                    self.errorMessages[player.id] = "\(improvement.name) cannot be rushed."
                    return req.redirect(to: "/main")
                default:
                    self.errorMessages[player.id] = error.localizedDescription
                    return req.redirect(to: "/main")
                }
                //return Future.map(on: req) { return req.redirect(to: "/main") }
            }
        }
        
        router.get("sell/improvement", Int.parameter) { req -> Response in
            let number: Int = try req.parameters.next()
            
            guard let shortName = Improvement.ShortName(rawValue: number) else {
                return req.redirect(to: "/main")
            }
            
            let player = try self.getPlayerFromSession(on: req)
            
            guard let improvement = Improvement.getImprovementByName(shortName) else {
                self.errorMessages[player.id] = "No improvement with shortName \(shortName) found."
                return req.redirect(to: "/main")
            }
            
            do {
                let sellingPlayer = try player.sellImprovement(improvement)
                self.simulation = try self.simulation.replacePlayer(sellingPlayer)
                self.infoMessages[sellingPlayer.id] = "Succesfully sold \(improvement.name)."
                return req.redirect(to: "/improvements")
            } catch {
                switch error {
                case Improvement.ImprovementError.improvementIncomplete:
                    self.errorMessages[player.id] = "You can only sell completed improvements."
                    return req.redirect(to: "/main")
                default:
                    self.errorMessages[player.id] = error.localizedDescription
                    return req.redirect(to: "/main")
                }
            }
        }
        
        router.get("mission/supportingPlayers") { req -> Future<View> in
            struct SupportingPlayerContext: Content {
                let player: Player
                let supportingPlayers: [Player]
                let mission: Mission
            }
            
            let player = try self.getPlayerFromSession(on: req)
            
            guard let mission = self.simulation.getSupportedMissionForPlayer(player) else {
                throw Abort(.notFound, reason: "Mission not found for player.")
            }
            
            let supportingPlayers = try self.simulation.supportingPlayersForMission(mission)
            
            let context = SupportingPlayerContext(player: player, supportingPlayers: supportingPlayers, mission: mission)
            return try req.view().render("mission_supportingPlayers", context)
        }
        
        router.get("unlock/technologies") { req -> Future<View> in
            struct UnlockTechnologyContext: Codable {
                let player: Player
                let possibleTechnologies: [Technology]
            }
            
            let player = try self.getPlayerFromSession(on: req)
            
            let possibleTechnologies = Technology.unlockableTechnologiesForPlayer(player)
            let context = UnlockTechnologyContext(player: player, possibleTechnologies: possibleTechnologies)
            
            return try req.view().render("technologies", context)
        }
        
        router.get("unlock/technologies", Int.parameter) { req -> Response in
            let number: Int = try req.parameters.next()
            
            guard let shortName = Technology.ShortName(rawValue: number) else {
                return req.redirect(to: "/main")
            }
            
            let player = try self.getPlayerFromSession(on: req)
            
            guard let technology = Technology.getTechnologyByName(shortName) else {
                self.errorMessages[player.id] = "No technology with shortName \(shortName) found."
                return req.redirect(to: "/main")
            }
            
            do {
                
                let unlockingPlayer = try player.investInTechnology(technology)
                self.simulation = try self.simulation.replacePlayer(unlockingPlayer)
                self.infoMessages[unlockingPlayer.id] = "Succesfully unlocked \(technology.name)."
                return req.redirect(to: "/technology")
            } catch {
                switch error {
                case Player.PlayerError.playerAlreadyUnlockedTechnology:
                    self.errorMessages[player.id] = "You already unlocked \(technology.name)."
                case Player.PlayerError.insufficientTechPoints:
                    self.errorMessages[player.id] = "Insufficient technology points to unlock \(technology.name)."
                case Player.PlayerError.playerMissesPrerequisiteTechnology:
                    self.errorMessages[player.id] = "You miss the prerequisite technology to unlock \(technology.name)."
                default:
                    throw error
                }
                return req.redirect(to: "/main")
            }
        }
        
        router.get("admin") { req -> Future<View> in
            struct FileInfo: Content {
                let fileName: String
                let creationDate: String
                let modifiedDate: String
                let isCurrentSimulation: Bool
            }
            
            struct AdminContext: Content {
                let player: Player
                let backupFiles: [FileInfo]
                let infoMessage: String?
                let errorMessage: String?
            }
            
            let player = try self.getPlayerFromSession(on: req)
            guard player.isAdmin else {
                throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
            }
            
            let dataDir = Environment.get("DATA_DIR") ?? ""
            let url = URL(fileURLWithPath: dataDir, isDirectory: true)
            
            let fm = FileManager.default
            let content = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            let filteredFiles = content.filter({file in file.pathExtension == "json" })
            
            let files = filteredFiles.map { file -> FileInfo in
                let fileName = file.lastPathComponent
                let attributes = try? fm.attributesOfItem(atPath: file.path)
                let creationDate: Date? = attributes?[FileAttributeKey.creationDate] as? Date
                let modifiedDate: Date? = attributes?[FileAttributeKey.modificationDate] as? Date
                let currentSimulation = fileName == "\(SIMULATION_FILENAME).json"
                
                return FileInfo(fileName: fileName, creationDate: creationDate?.description ?? "", modifiedDate: modifiedDate?.description ?? "", isCurrentSimulation: currentSimulation)
            }
            
            let sortedFiles = files.sorted { file1, file2 in file1.modifiedDate > file2.modifiedDate }
            
            let context = AdminContext(player: player, backupFiles: sortedFiles, infoMessage: self.infoMessages[player.id] ?? nil, errorMessage: self.errorMessages[player.id] ?? nil)
            return try req.view().render("admin/admin", context)
        }
        
        router.get("admin", "backupnow") { req -> Response in
            let player = try self.getPlayerFromSession(on: req)
            guard player.isAdmin else {
                throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
            }
            
            do {
                let dataDir = Environment.get("DATA_DIR") ?? ""
                let formatter = DateFormatter()
                formatter.dateFormat = "YYYYMMdd_HHmmss"
                
                let formattedDate = formatter.string(from: Date())
                //print(formattedDate)
                let data = try self.simulation.save(fileName: "backup_\(formattedDate).json", path: dataDir)
                self.infoMessages[player.id] = "Succesfully backed up to file: backup_\(formattedDate).json)"
                
                let result = try Storage.upload(
                    bytes: data,
                    fileName: "test",
                    fileExtension: "json",
                    folder: "data",
                    on: req
                )
                print(result)
                
                
            } catch {
                self.errorMessages[player.id] = "Failed to backup due to error: \(error.localizedDescription)"
            }
            
            return req.redirect(to: "/admin")
        }
        
        router.get("admin", "restore", String.parameter, String.parameter) { req -> Response in
            let player = try self.getPlayerFromSession(on: req)
            guard player.isAdmin else {
                throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
            }
            
            let fileName = try req.parameters.next(String.self)
            let loadMode = (try req.parameters.next(String.self)) == "replace"
            
            do {
                
                let dataDir = Environment.get("DATA_DIR") ?? ""
                if let simulation = Simulation.load(fileName: fileName, path: dataDir) {
                    if (loadMode) { self.simulation = simulation }
                    if (loadMode) {
                        self.infoMessages[player.id] = ("Succesfully loaded simulation from file: \(dataDir+fileName)")
                    } else {
                        self.infoMessages[player.id] = ("\(dataDir + fileName) is a valid simulation.")
                    }
                } else {
                self.errorMessages[player.id] = ("Could not load simulation from file: \(fileName)")
                }
            }
        
        return req.redirect(to: "/admin")
        }
        
        router.get("debug", "allUsers") { req -> [Player] in
            guard (Environment.get("DEBUG_MODE") ?? "inactive") == "active" else {
                throw Abort(.notFound)
            }
            return self.simulation.players
        }
        
        router.post("debug", "cash") { req -> [Player] in
            guard (Environment.get("DEBUG_MODE") ?? "inactive") == "active" else {
                throw Abort(.notFound)
            }
            
            let richPlayers = self.simulation.players.map { player -> Player in
                var changedPlayer = player
                changedPlayer.debug_setCash(4_000_000_000)
                return changedPlayer
            }
            
            for player in richPlayers {
                self.simulation = try self.simulation.replacePlayer(player)
            }
            return self.simulation.players
        }
        
        router.post("debug", "tech") { req -> [Player] in
            guard (Environment.get("DEBUG_MODE") ?? "inactive") == "active" else {
                throw Abort(.notFound)
            }
            
            let smartPlayers = self.simulation.players.map { player -> Player in
                var changedPlayer = player
                changedPlayer.debug_setTech(2_000)
                return changedPlayer
            }
            
            for player in smartPlayers {
                self.simulation = try self.simulation.replacePlayer(player)
            }
            return self.simulation.players
        }
        
        router.post("debug", "createDummyUsers") { req -> [Player] in
            guard (Environment.get("DEBUG_MODE") ?? "inactive") == "active" else {
                throw Abort(.notFound)
            }
            
            for i in 0 ..< 1_000 {
                let result = try self.simulation.createPlayer(emailAddress: "dummyUser\(i)\(Int.random(in: 0...1_000_000))@example.com", name: "dummyUser\(i)\(Int.random(in: 0...1_000_000))")
                self.simulation = result.updatedSimulation
            }
            return self.simulation.players
        }
        
        router.get() { req in
            return try req.view().render("index")
        }
        
        router.get("debug/dataDump") { req -> String in
            guard (Environment.get("DEBUG_MODE") ?? "inactive") == "active" else {
                throw Abort(.notFound)
            }
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(self.simulation)
                return String(data: data, encoding: .utf8) ?? "empty"
            } catch {
                print(error)
                return("Error while backup up: \(error).")
            }
        }
    }
            
    func getPlayerIDFromSession(on req: Request) -> UUID? {
        if let session = try? req.session() {
            if let playerID = session["playerID"] {
                return UUID(playerID)
            }
        }
        return nil
    }
    
    func getMainViewForPlayer(with id: UUID, simulation: Simulation, on req: Request, page: String = "overview") throws -> Future<View> {
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
        }
        
        guard let player = self.simulation.players.first(where: {somePlayer in somePlayer.id == id}) else {
            print("Could not find user with id: \(id)")
            return try req.view().render("index")
        }
        
        let errorMessage = self.errorMessages[id] ?? nil
        self.errorMessages.removeValue(forKey: id)
        let infoMessage = self.infoMessages[id] ?? nil
        self.infoMessages.removeValue(forKey: id)
 
        if let mission = self.simulation.getSupportedMissionForPlayer(player) {
            if mission.missionComplete {
                return try req.view().render("win")
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
            
            let context = MainContext(player: player, mission: mission, currentStage: mission.currentStage, currentBuildingComponents: mission.currentStage.currentlyBuildingComponents, simulation: simulation, errorMessage: errorMessage, infoMessage: infoMessage, currentStageComplete: mission.currentStage.stageComplete, unlockableTechnologogies: Technology.unlockableTechnologiesForPlayer(player), unlockedTechnologies: player.unlockedTechnologies, unlockedComponents: unlockedComponents, techlockedComponents: techlockedComponents, playerIsBuildingComponent: mission.currentStage.playerIsBuildingComponentInStage(player), cashPerDay: player.cashPerTick, techPerDay: player.techPerTick, componentBuildPointsPerDay: player.componentBuildPointsPerTick,  page: page, simulationIsUpdating: self.simulationIsUpdating)
            
            return try req.view().render("main", context)
        } else {
            // no mission
            let context = MainContext(player: player, mission: nil, currentStage: nil, currentBuildingComponents: [], simulation: simulation, errorMessage: errorMessage, infoMessage: infoMessage,  currentStageComplete: false, unlockableTechnologogies: Technology.unlockableTechnologiesForPlayer(player), unlockedTechnologies: player.unlockedTechnologies, unlockedComponents: [], techlockedComponents: [], playerIsBuildingComponent: false, cashPerDay: player.cashPerTick, techPerDay: player.techPerTick, componentBuildPointsPerDay: player.componentBuildPointsPerTick, page: page, simulationIsUpdating: self.simulationIsUpdating)
            
            return try req.view().render("main", context)
        }
    }
    
    func getPlayerFromSession(on req: Request) throws -> Player {
        guard let id = getPlayerIDFromSession(on: req) else {
            throw Abort(.unauthorized)
        }
        
        guard let player = simulation.players.first(where: {player in player.id == id }) else {
            throw Abort(.unauthorized)
        }
        
        return player
    }
    
    func sendWelcomeEmail(to player: Player, on container: Container) {
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

//
//  FrontEndController.swift
//  App
//
//  Created by Maarten Engels on 29/12/2019.
//

import Foundation
import Vapor
import Leaf
import SotoS3

func createFrontEndRoutes(_ app: Application) {
    let BACKUP_INTERVAL = 12
    var counter = 0
    
    let session = app.routes.grouped([
        SessionsMiddleware(session: app.sessions.driver),
        UserSessionAuthenticator(),
        UserCredentialsAuthenticator(),
    ])
    
    app.get() { req -> EventLoopFuture<View> in
        struct IndexContext: Encodable {
            let state: Simulation.SimulationState
            let motd: String?
            let isIndexPage = true
        }
        
        let motd = app.motd
        let context = IndexContext(state: app.simulation.state, motd: motd)
        return req.view.render("index", context)
    }
    
    // MARK: Create player
    app.get("create", "player") { req -> EventLoopFuture<View> in
        return req.view.render("createPlayer", ["startingImprovements": Improvement.startImprovements])
    }
        
    app.post("create", "player") { req -> EventLoopFuture<View> in
        struct CreateCharacterContext: Codable {
            var errorMessage = "noError"
            var name = ""
            var email = ""
            var uuid = "unknown"
        }
        let emailAddress: String = try req.content.get(at: "emailAddress")
        let name: String = try req.content.get(at: "name")
        let shortNameForm: Int = try req.content.get(at: "startingImprovement")
        let password: String = try req.content.get(at: "password")
        let passwordRepeat: String = try req.content.get(at: "passwordRepeat")
        
        guard password == passwordRepeat else {
            throw Abort(.badRequest, reason: "Passwords don't match.")
        }
        
        guard let startingImprovement = Improvement.ShortName.init(rawValue: shortNameForm) else {
            throw Abort(.badRequest, reason: "Invalid starting improvement shortname \(shortNameForm).")
        }
        
        var context = CreateCharacterContext()
        do {
            let result = try app.simulation.createPlayer(emailAddress: emailAddress, name: name, password: password, startImprovementShortName: startingImprovement)
            app.simulation = result.updatedSimulation
            
            context.email = emailAddress
            context.name = name
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
    
    func sendWelcomeEmail(to player: Player, on container: Request) {
        if let publicKey = Environment.get("MAILJET_API_KEY"), let privateKey = Environment.get("MAILJET_SECRET_KEY") {
        
        let mailJetConfig = MailJetConfig(apiKey: publicKey, secretKey: privateKey, senderName: "Mission2Mars Support", senderEmail: "support@mission2mars.space")
        mailJetConfig.sendMessage(to: player.emailAddress, toName: player.name, subject: "Your login id", message: """
            Welcome \(player.name) to Mission2Mars
            
            Your username is: \(player.name)
            Your registered email address is: \(player.emailAddress)
            
            Note: if you lose your password, you need both your registered email address and username to request a new password.

            If you don't recognize signing up to Mission2Mars, please let us know by replying to this e-mail. Otherwise,

            Have fun!
            
            - the Mission2Mars team
            Sent from: \(Environment.get("ENVIRONMENT") ?? "local test")
            """, htmlMessage: """
            <h1>Welcome \(player.name) to Mission2Mars</h1>
            
            <h3>Your username is: <b>\(player.name)</b></h3>
            <h3>Your registered email address is: \(player.emailAddress)</h3>
            <p>Note: if you lose your password, you need both your registered email address and username to request a new password.</p>
            <p>&nbsp;</p>
            <p>If you don't recognize signing up to Mission2Mars, please let us know by replying to this e-mail. Otherwise,</p>
            <p>&nbsp;</p>
            <p>Have fun!</p>
            <p>&nbsp;</p>
            <p>- the Mission2Mars team</p>
            <p>Sent from: \(Environment.get("ENVIRONMENT") ?? "unknown")</p>
            """, on: container)
        }
    }
    
    // MARK: Login
    app.post("login") { req -> EventLoopFuture<View> in
        let emailAddress: String = try req.content.get(at: "emailAddress")
        let password: String = try req.content.get(at: "password")
        
        guard let user = app.simulation.players.first(where: { player in player.emailAddress == emailAddress }) else {
            app.logger.warning("Attempt to login for unknown user with email address \(emailAddress).")
            return req.view.render("index", ["errorMessage": "Invalid email address/password combination."])
        }
        
        if try Bcrypt.verify(password, created: user.hashedPassword) {
            req.auth.login(user)
            app.logger.notice("Successfull login for user \(user.name)")
            req.session.authenticate(user)
            
            if app.simulation.state == .admin {
                return try adminPage(on: req, with: app.simulation, in: app)
            } else {
                return try mainPage(req: req, page: "main")
            }
            
            
        } else {
            app.logger.warning("Password mismatch for user \(user.name)")
            return req.view.render("index", ["errorMessage": "Invalid email address/password combination."])
        }
    }
    
    func getPlayerIDFromSession(on req: Request) -> UUID? {
        (try? req.getPlayerFromSession())?.id
    }
    
    func getPlayerFromSession(on req: Request, in simulation: Simulation) throws -> Player {
        guard let user = req.auth.get(Player.self) else {
            throw Abort(.unauthorized)
        }
        return user
    }
    
    // MARK: Get mail pages (mission, technology, improvements)
    session.get("main") { req -> EventLoopFuture<View> in
        return try mainPage(req: req, page: "main")
    }
        
    session.get("mission") { req in
        return try mainPage(req: req, page: "mission")
    }
        
    session.get("technology") { req in
        return try mainPage(req: req, page: "technology")
    }
        
    session.get("improvements") { req in
        return try mainPage(req: req, page: "improvements")
    }
      
    /// Retrieves the mail page.
    /// * Updates simulation when past next update time
    /// * Saves simulation to cloud storage every `BACKUP_INTERVAL` times
    func mainPage(req: Request, page: String) throws -> EventLoopFuture<View> {
        guard let player = try? req.getPlayerFromSession() else {
            return req.view.render("index", ["state": app.simulation.state])
        }
        
        if app.simulation.simulationShouldUpdate(currentDate: Date()) {
            let updatedSimulation = app.simulation.updateSimulation(currentDate: Date())
            assert(app.simulation.id == updatedSimulation.id)
            app.simulation = updatedSimulation
            app.logger.notice("\(Date()) - Updated simulation.")
            
            counter -= 1

            if counter < 0 {
                app.logger.notice("Start simulation save/backup.")
                // save result (in seperate thread)
                let copy = app.simulation
                let dataDir = Environment.get("DATA_DIR") ?? ""
                do {
                    let path = try copy.save(path: dataDir)
                    let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
            
                    let s3 = S3(client: app.aws.client, region: nil, partition: AWSPartition.awsiso, endpoint: "https://m2m.ams3.digitaloceanspaces.com", timeout: nil, byteBufferAllocator: ByteBufferAllocator(), options: [])
                    //let s3 = S3(client: app.aws.client, accessKeyId: accessKey, secretAccessKey: secretKey, region: .euwest1, endpoint: "https://m2m.ams3.digitaloceanspaces.com")

                    let uploadRequest = S3.CreateMultipartUploadRequest(acl: .private, bucket: bucket, key: SIMULATION_FILENAME + "_\(Date().hashValue)" + ".json")
                       
                     _ = s3.multipartUpload(uploadRequest,
                                              partSize: 5*1024*1024,
                                              filename: path.path,
                                              on: req.eventLoop,
                                              progress: { progress in print(progress) }
                     ).map { result in
                        app.logger.notice("\(Date()) - Save result: \(result)")
                     }
                    
                    counter = BACKUP_INTERVAL
                    
                    return try getMainViewForPlayer(updatedSimulation.players.first(where: {$0.id == player.id}) ?? player, simulation: app.simulation, on: req, page: page)
                } catch {
                    req.logger.error("Failed to save simulation due to error: \(error).")
                }
            }
        }
        
        return try getMainViewForPlayer(player, simulation: app.simulation, on: req, page: page)
    }
    
    func getMainViewForPlayer(_ player: Player, simulation: Simulation, on req: Request, page: String = "main") throws -> EventLoopFuture<View> {
        struct ImprovementContext: Codable {
            let slot: Int
            let improvement: Improvement
        }
        
        struct ComponentContext: Codable {
            let component: Component
            let buildingPlayerName: String
        }
        
        struct MainContext: Codable {
            let player: Player
            let mission: Mission?
            let currentStage: Stage?
            //let currentBuildingComponents: [ComponentContext]
            let simulation: Simulation
            let errorMessage: String?
            let infoMessage: String?
            let currentStageComplete: Bool
            let unlockableTechnologogies: [Technology]
            let unlockedTechnologies: [Technology]
            let unlockedComponents: [ComponentContext]
            let techlockedComponents: [Component]
            let playerIsBuildingComponent: Bool
            let cashPerDay: Double
            let techPerDay: Double
            let componentBuildPointsPerDay: Double
            let page: String
            let simulationIsUpdating: Bool
            let improvements: [ImprovementContext]
            let improvementSlots: Int
            let specializationSlots: Int
            let specilizationCount: Int
            let improvementCount: Int
            let secondsUntilNextUpdate: Int
        }
        
        let id = player.id
        
        var errorMessages = app.errorMessages
        let errorMessage = errorMessages[id] ?? nil
        errorMessages.removeValue(forKey: id)
        app.errorMessages = errorMessages
        
        var infoMessages = app.infoMessages
        let infoMessage = app.infoMessages[id] ?? nil
        infoMessages.removeValue(forKey: id)
        app.infoMessages = infoMessages
 
        let secondsUntilNextUpdate = abs(app.simulation.nextUpdateDate.timeIntervalSince(Date()))
        
        var improvements = [ImprovementContext]()
        for i in 0 ..< player.improvements.count {
            improvements.append(ImprovementContext(slot: i, improvement: player.improvements[i]))
        }
        
        if let mission = app.simulation.getSupportedMissionForPlayer(player) {
            if mission.missionComplete {
                return req.view.render("win", ["player": player])
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
            
            let unlockedComponentContext = unlockedComponents.map { component -> ComponentContext in
                let buildingPlayer = simulation.players.first { $0.id == component.builtByPlayerID }
                return ComponentContext(component: component, buildingPlayerName: buildingPlayer?.name ?? "unknown")
            }
            
            let context = MainContext(player: player,
                                      mission: mission,
                                      currentStage: mission.currentStage,
                                      //currentBuildingComponents: mission.currentStage.currentlyBuildingComponents,
                                      simulation: simulation,
                                      errorMessage: errorMessage,
                                      infoMessage: infoMessage,
                                      currentStageComplete: mission.currentStage.stageComplete,
                                      unlockableTechnologogies: Technology.unlockableTechnologiesForPlayer(player),
                                      unlockedTechnologies: player.unlockedTechnologies,
                                      unlockedComponents: unlockedComponentContext,
                                      techlockedComponents: techlockedComponents,
                                      playerIsBuildingComponent: mission.currentStage.playerIsBuildingComponentInStage(player),
                                      cashPerDay: player.cashPerTick,
                                      techPerDay: player.techPerTick,
                                      componentBuildPointsPerDay: player.componentBuildPointsPerTick,
                                      page: page,
                                      simulationIsUpdating: false,
                                      improvements: improvements,
                                      improvementSlots: player.improvementSlotsCount,
                                      specializationSlots: player.maximumNumberOfSpecializations,
                                      specilizationCount: player.specilizationCount,
                                      improvementCount: player.improvements.count,
                                      secondsUntilNextUpdate:
                                        Int(secondsUntilNextUpdate))
            
            return req.view.render("main_\(page)", context)
        } else {
            // no mission
            let context = MainContext(player: player, mission: nil, currentStage: nil, //currentBuildingComponents: [],
                                      simulation: simulation,
                                      errorMessage: errorMessage,
                                      infoMessage: infoMessage,
                                      currentStageComplete: false,
                                      unlockableTechnologogies: Technology.unlockableTechnologiesForPlayer(player),
                                      unlockedTechnologies: player.unlockedTechnologies,
                                      unlockedComponents: [],
                                      techlockedComponents: [],
                                      playerIsBuildingComponent: false,
                                      cashPerDay: player.cashPerTick,
                                      techPerDay: player.techPerTick,
                                      componentBuildPointsPerDay: player.componentBuildPointsPerTick,
                                      page: page, simulationIsUpdating: false,
                                      improvements: improvements,
                                      improvementSlots: player.improvementSlotsCount,
                                      specializationSlots: player.maximumNumberOfSpecializations,
                                      specilizationCount: player.specilizationCount,
                                      improvementCount: player.improvements.count,
                                      secondsUntilNextUpdate: Int(secondsUntilNextUpdate))
            
            return req.view.render("main_\(page)", context)
        }
    }
    
    // MARK: Manage Missions (create, edit, support)
    session.get("edit", "mission") { req -> EventLoopFuture<View> in
        let player = try req.getPlayerFromSession()
        
        guard let supportedMission = app.simulation.getSupportedMissionForPlayer(player) else {
            throw Abort(.notFound, reason: "No supported mission found for player.")
        }
        
        return req.view.render("editMission", ["missionName": supportedMission.missionName])
    }
        
    session.post("edit", "mission") { req -> Response in
        let newName: String = try req.content.get(at: "missionName")
        
        let player = try req.getPlayerFromSession()
        
        if let supportedMission = app.simulation.getSupportedMissionForPlayer(player) {
            var changedMission = supportedMission
            changedMission.missionName = newName
            let updatedSimulation = try app.simulation.replaceMission(changedMission)
            app.simulation = updatedSimulation
        }
        
        return req.redirect(to: "/mission")
    }
        
    session.get("create", "mission") { req -> Response in
        let player = try req.getPlayerFromSession()
        app.simulation = try app.simulation.createMission(for: player)
        return req.redirect(to: "/mission")
    }
        
    session.get("support", "mission") { req -> EventLoopFuture<View> in
        _ = try req.getPlayerFromSession()
        
        let unfinishedMissions = app.simulation.missions.filter { mission in mission.missionComplete == false }
        
        let mcs = unfinishedMissions.map { mission -> MissionContext in
            let owningPlayer = app.simulation.players.first(where: { somePlayer in somePlayer.id == mission.owningPlayerID })?.name ?? "unknown"
            return MissionContext(id: mission.id, missionName: mission.missionName, percentageDone: mission.percentageDone, owningPlayerName: owningPlayer)
        }
        
        return req.view.render("missions", ["missions": mcs])
    }
        
    session.get("support", "mission", ":id") { req -> Response in
        guard let supportedMissionID = UUID(req.parameters.get("id") ?? "") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("id") ?? "-") is not a valid GUID.")
        }
        let player = try req.getPlayerFromSession()
        
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
    
    session.get("mission", "supportingPlayers") { req -> EventLoopFuture<View> in
        struct SupportingPlayerContext: Content {
            let player: Player
            let supportingPlayers: [Player]
            let mission: Mission
        }
        
        let player = try req.getPlayerFromSession()
        
        guard let mission = app.simulation.getSupportedMissionForPlayer(player) else {
            throw Abort(.notFound, reason: "Mission not found for player.")
        }
        
        let supportingPlayers = try app.simulation.supportingPlayersForMission(mission)
        
        let context = SupportingPlayerContext(player: player, supportingPlayers: supportingPlayers, mission: mission)
        return req.view.render("mission_supportingPlayers", context)
    }
        
    // MARK: Donations
    session.get("donate", "to", ":receivingPlayerEmail") { req -> EventLoopFuture<View> in
        struct DonateContext: Content {
            let player: Player
            let receivingPlayerName: String
            let receivingPlayerEmail: String
        }
        
        let receivingPlayerEmail = req.parameters.get("receivingPlayerEmail") ?? ""
        let player = try req.getPlayerFromSession()
        
        guard let receivingPlayer = app.simulation.players.first(where: {somePlayer in somePlayer.emailAddress == receivingPlayerEmail}) else {
            throw Abort(.notFound, reason: "Could not find player with emailadress \(receivingPlayerEmail)")
        }
        
        let context = DonateContext(player: player, receivingPlayerName: receivingPlayer.name, receivingPlayerEmail: receivingPlayer.emailAddress)
        return req.view.render("donate", context)
    }
        
    session.get("donate", "to", ":receivingPlayerEmail", "cash", ":donateString") { req -> Response in
        let donatingPlayer = try req.getPlayerFromSession()
        
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
        
    session.get("donate", "to", ":receivingPlayerEmail", "tech", ":tpString") { req -> Response in
        let donatingPlayer = try req.getPlayerFromSession()
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
    
    // MARK: Build components
    session.get("build", "component", ":shortNameString") { req -> Response in
        let player = try req.getPlayerFromSession()
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
        
    session.get("advance", "stage") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard let mission = app.simulation.getSupportedMissionForPlayer(player) else {
            throw Abort(.badRequest, reason: "No mission for player")
        }
        
        let advancedMission = try mission.goToNextStage()
        app.simulation = try app.simulation.replaceMission(advancedMission)
        return req.redirect(to: "/mission")
    }
    
    // MARK: Build Improvements
    session.get("build", "improvements") { req -> EventLoopFuture<View> in
        struct ImprovementInfo: Codable {
            let improvement: Improvement
            let canBuild: Bool
        }
        struct ImprovementBuildContext: Codable {
            let player: Player
            let buildPointsPerTick: Double
            let possibleImprovements: [ImprovementInfo]
        }
        
        let player = try req.getPlayerFromSession()
        
        let possibleImprovements: [ImprovementInfo]
        let onlyBuildable: Bool = (try? req.query.get(at: "buildable")) ?? false
        if onlyBuildable {
            possibleImprovements = Improvement.unlockedImprovementsForPlayer(player)
                .filter({ improvement in player.canBuildImprovement(improvement)})
                .map { improvement in
                    ImprovementInfo(improvement: improvement, canBuild: true) }
        } else {
            possibleImprovements = Improvement.unlockedImprovementsForPlayer(player)
                .map { improvement in
                    ImprovementInfo(improvement: improvement, canBuild: player.canBuildImprovement(improvement))
            }
        }
        
        let context = ImprovementBuildContext(player: player, buildPointsPerTick: player.buildPointsPerTick, possibleImprovements: possibleImprovements)
        
        return req.view.render("improvements", context)
    }
        
    session.get("build", "improvements", ":number") { req -> Response in
        guard let number = Int(req.parameters.get("number") ?? "") else {
            throw Abort (.badRequest, reason: "\(req.parameters.get("number") ?? "") is not a valid Integer.")
        }
        
        guard let shortName = Improvement.ShortName(rawValue: number) else {
            return req.redirect(to: "/main")
        }
        
        let player = try req.getPlayerFromSession()
        
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
            case Player.PlayerError.insufficientSpecializationSlots:
                app.errorMessages[player.id] = "You can't build \(improvement.name) because you don't have any available specialization slots)"
            case Improvement.ImprovementError.improvementIsUnique:
                app.errorMessages[player.id] = "\(improvement.name) is unique. This means you can't build more than one of each."
                return req.redirect(to: "/main")
            default:
                throw error
            }
            return req.redirect(to: "/main")
        }
    }
        
    session.get("sell", "improvement", ":number") { req -> Response in
        guard let number = Int(req.parameters.get("number") ?? "") else {
            throw Abort (.badRequest, reason: "\(req.parameters.get("number") ?? "") is not a valid Integer.")
        }
        
        guard let shortName = Improvement.ShortName(rawValue: number) else {
            return req.redirect(to: "/main")
        }
        
        let player = try req.getPlayerFromSession()
        
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
    
    // FIXME: Consider removing rushing or changing mechanic (i.e. BUY)
    session.get("rush", "improvements", ":number") { req -> Response in
        guard let number =  Int(req.parameters.get("number") ?? "") else {
            throw Abort (.badRequest, reason: "\(req.parameters.get("number") ?? "") is not a valid Integer.")
        }
        
        let player = try req.getPlayerFromSession()
        
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
        
    /*
    session.get("trigger", "improvements", ":number") { req -> Response in
        guard let number =  Int(req.parameters.get("number") ?? "") else {
            throw Abort (.badRequest, reason: "\(req.parameters.get("number") ?? "") is not a valid Integer.")
        }
        
        let player = try req.getPlayerFromSession()
        
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
     */
        
    // MARK: Technology
    session.get("unlock", "technologies") { req -> EventLoopFuture<View> in
        struct UnlockTechnologyContext: Codable {
            let player: Player
            let possibleTechnologies: [Technology]
        }
        
        let player = try req.getPlayerFromSession()
        
        let possibleTechnologies = Technology.unlockableTechnologiesForPlayer(player)
        let context = UnlockTechnologyContext(player: player, possibleTechnologies: possibleTechnologies)
        
        return req.view.render("technologies", context)
    }
        
    session.get("unlock", "technologies", ":number") { req -> Response in
        guard let number = Int(req.parameters.get("number") ?? "") else {
            throw Abort (.badRequest, reason: "\(req.parameters.get("number") ?? "") is not a valid Integer.")
        }
        
        guard let shortName = Technology.ShortName(rawValue: number) else {
            return req.redirect(to: "/main")
        }
        
        let player = try req.getPlayerFromSession()
        
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
        
    // MARK: DEBUG
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
            changedPlayer.debug_setTech(3_000)
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
            let result = try app.simulation.createPlayer(emailAddress: "dummyUser\(i)\(Int.random(in: 0...1_000_000))@example.com", name: "dummyUser\(i)\(Int.random(in: 0...1_000_000))", password: "foo")
            app.simulation = result.updatedSimulation
        }
        return app.simulation.players
    }
        
    /*app.get("debug", "dataDump") { req -> String in
        guard (Environment.get("DEBUG_MODE") ?? "inactive") == "active" else {
            throw Abort(.notFound)
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(app.simulation)
            return String(data: data, encoding: .utf8) ?? "empty"
        } catch {
            req.logger.error("Error while backing up: \(error)")
            return("Error while backup up: \(error).")
        }
    }*/
}

struct MissionContext: Content {
    let id: UUID
    let missionName: String
    let percentageDone: Double
    let owningPlayerName: String
}

//
//  Player.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation
import FluentSQLite
import Vapor

public struct Player: Content, SQLiteUUIDModel {
    public enum PlayerError: Error {
        case noMission
        case insufficientFunds
        case insufficientTechPoints
        case noSupportedPlayer
        case userAlreadyExists
        
        case userDoesNotExist
        case playerAlreadyHasImprovement
        case usernameFailedValidation
        case playerAlreadyUnlockedTechnology
        case playerMissesPrerequisiteTechnology
        
        case playerIsAlreadyBuildingImprovement
        case playerNotFound
        case playersNotInSameMission
        case cannotDonateToYourself
        case illegalImprovementSlot
        
        case insufficientImprovementSlots
    }
    
    public var id: UUID?
    
    public let emailAddress: String
    public let name: String
    
    public var ownsMissionID: UUID?
    public var supportsPlayerID: UUID?
    
    public private(set) var unlockedTechnologyNames: [Technology.ShortName]
    public var unlockedTechnologies: [Technology] {
        return unlockedTechnologyNames.compactMap { techName in
            return Technology.getTechnologyByName(techName)
        }
    }
    
    // resources
    public private(set) var cash: Double = 2_500_000
    public private(set) var technologyPoints: Double = 75
    public private(set) var buildPoints: Double = 0
    public private(set) var componentBuildPoints: Double = 0
    
    public private(set) var improvements: [Improvement]
    public var currentlyBuildingImprovement: Improvement? {
        let unfinishedImprovements = improvements.filter { improvement in
            return improvement.buildStartedOn != nil && improvement.isCompleted == false
        }
        return unfinishedImprovements.first
    }
    
    public var isCurrentlyBuildingImprovement: Bool {
        return currentlyBuildingImprovement != nil
    }
    
    public init(emailAddress: String, name: String, startImprovementShortName: Improvement.ShortName = .TechConsultancy) {
        self.emailAddress = emailAddress
        self.name = name
        self.improvements = []
        
        let startImprovement = Improvement.getImprovementByName(startImprovementShortName)!
        if let completedStartImprovement = try? startImprovement.startBuild(startDate: Date()).updateImprovement(buildPoints: Double(startImprovement.buildTime)) {
            assert(completedStartImprovement.updatedImprovement.isCompleted, "Your starting tech consultancy firm should be complete.")
            self.improvements = [completedStartImprovement.updatedImprovement]
        }
        
        self.unlockedTechnologyNames = [Technology.ShortName.LiIonBattery]
    }
    
    var completedImprovements: [Improvement] {
        return improvements.filter { improvement in
            return improvement.isCompleted
        }
    }
    
    /*var buildTimeFactor: Double {
        let allEffects = completedImprovements.map { improvement in
            return improvement.staticEffects
            }.joined()
        
        let rawBuildTimeFactor = allEffects.reduce(1.0) { result, effect in
            switch effect {
            case .lowerProductionTimePercentage(let percentage):
                return result - (percentage / 100.0)
            default:
                return result
            }
        }
        
        return max(rawBuildTimeFactor, 0.1)
    }*/
    
    /*var componentDiscount: Double {
        let allEffects = completedImprovements.map { improvement in
            return improvement.staticEffects
            }.joined()
        
        let rawDiscount = allEffects.reduce(1.0) { result, effect in
            switch effect {
            case .componentBuildDiscount(let percentage):
                return result - (percentage / 100.0)
            default:
                return result
            }
        }
        
        return max(rawDiscount, 0.1)
    }*/
    
    /*var componentBuildTimeFactor: Double {
        let allEffects = completedImprovements.map { improvement in
            return improvement.staticEffects
            }.joined()
        
        let rawBuildTimeFactor = allEffects.reduce(1.0) { result, effect in
            switch effect {
            case .shortenComponentBuildTime(let percentage):
                return result - (percentage / 100.0)
            default:
                return result
            }
        }
        
        return max(rawBuildTimeFactor, 0.1)
    }*/
    
    public func updatePlayer(ticks: Int = 1) -> Player {
        var updatedPlayer = self
        updatedPlayer.componentBuildPoints = 1
        
        for _ in 0 ..< ticks {
            if isCurrentlyBuildingImprovement { updatedPlayer.buildPoints += 1 }
            
            for improvement in updatedPlayer.improvements {
                updatedPlayer = improvement.applyEffectForOwner(player: updatedPlayer)
            }
            //print("Player build points before: \(updatedPlayer.componentBuildPoints)")
            
            var updatedImprovements = updatedPlayer.improvements
            
            for i in 0 ..< updatedPlayer.improvements.count {
                let result = updatedImprovements[i].updateImprovement(buildPoints: updatedPlayer.buildPoints)
                updatedImprovements[i] = result.updatedImprovement
                updatedPlayer.buildPoints = result.remainingBuildPoints
            }
            
            updatedPlayer.improvements = updatedImprovements
            //print("Player build points after: \(updatedPlayer.buildPoints)")
        }
        
        //print("cashPerTick: \(cashPerTick)")
        //print(updatedPlayer)
        return updatedPlayer
    }
    
    public var cashPerTick: Double {
        let updatedPlayer = self.updatePlayer()
        return updatedPlayer.cash - cash
    }
    
    public var techPerTick: Double {
        let allEffects = completedImprovements.map { improvement in
            return improvement.updateEffects
            }.joined()
        
        let flatTechPerTick = allEffects.reduce(0.0) { result, effect in
            switch effect {
            case .extraTechFlat(let amount):
                return result + amount
            default:
                return result
            }
        }
        
        return flatTechPerTick
    }

    public var improvementSlotsCount: Int {
        return 5
    }
    
    func extraIncome(amount: Double) -> Player {
        var changedPlayer = self
        changedPlayer.cash += amount
        return changedPlayer
    }
    
    func extraTech(amount: Double) -> Player {
        var changedPlayer = self
        changedPlayer.technologyPoints += amount
        return changedPlayer
    }
    
    func extraBuildPoints(amount: Double) -> Player {
        var changedPlayer = self
        changedPlayer.buildPoints += amount
        return changedPlayer
    }
    
    func extraComponentBuildPoints(amount: Double) -> Player {
        var changedPlayer = self
        changedPlayer.componentBuildPoints += amount
        return changedPlayer
    }
    
    func donate(cash amount: Double, to player: Player) throws -> (donatingPlayer: Player, receivingPlayer: Player) {
        guard amount <= self.cash else {
            throw PlayerError.insufficientFunds
        }
        
        guard player.emailAddress != self.emailAddress else {
            throw PlayerError.cannotDonateToYourself
        }
        
        var receivingPlayer = player
        var donatingPlayer = self
        
        receivingPlayer.cash += amount
        donatingPlayer.cash -= amount
        
        return (donatingPlayer, receivingPlayer)
    }
    
    func donate(techPoints amount: Double, to player: Player) throws -> (donatingPlayer: Player, receivingPlayer: Player) {
        guard amount <= self.technologyPoints else {
            throw PlayerError.insufficientTechPoints
        }
        
        guard player.emailAddress != self.emailAddress else {
            throw PlayerError.cannotDonateToYourself
        }
        
        var receivingPlayer = player
        var donatingPlayer = self
        
        receivingPlayer.technologyPoints += amount
        donatingPlayer.technologyPoints -= amount
        
        return (donatingPlayer, receivingPlayer)
    }
    
    func investInComponent(_ component: Component, in mission: Mission, date: Date) throws -> (changedPlayer: Player, changedMission: Mission) {
        var updatedPlayer = self
        var updatedMission = mission
        
        guard mission.currentStage.unstartedComponents.contains(component) else {
            return (updatedPlayer, updatedMission)
        }
        
        let netCost = component.cost * 1.0
        
        guard cash >= netCost else {
            throw PlayerError.insufficientFunds
        }
        
        guard component.playerHasPrerequisitesForComponent(self) else {
            throw PlayerError.playerMissesPrerequisiteTechnology
        }
        
        updatedMission = try updatedMission.startBuildingInStage(component, buildDate: date, by: self)
        updatedPlayer.cash -= netCost
        
        return (updatedPlayer, updatedMission)
    }
        
    public func startBuildImprovement(_ improvement: Improvement, startDate: Date) throws -> Player {
        // This is no longer relevant if we want to allow the same building built more than once. 
        /*guard improvements.contains(improvement) == false else {
            throw PlayerError.playerAlreadyHasImprovement
        }*/
        
        guard improvements.count < improvementSlotsCount else {
            throw PlayerError.insufficientImprovementSlots
        }
        
        guard improvement.playerHasPrerequisitesForImprovement(self) else {
            throw PlayerError.playerMissesPrerequisiteTechnology
        }
        
        guard cash >= improvement.cost else {
            throw PlayerError.insufficientFunds
        }
        
        if let buildingImprovement = currentlyBuildingImprovement {
            if buildingImprovement.allowsParrallelBuild == false || improvement.allowsParrallelBuild == false {
                throw PlayerError.playerIsAlreadyBuildingImprovement
            }
        }
        
        let buildingImprovement = try improvement.startBuild(startDate: startDate)
        
        var changedPlayer = self
        
        changedPlayer.improvements.append(buildingImprovement)
        assert(buildingImprovement.percentageCompleted == 0)
        assert(changedPlayer.improvements.last!.buildStartedOn != nil)
        changedPlayer.cash -= improvement.cost
        
        return changedPlayer
    }
    
    func replaceImprovementInSlot(_ slot: Int, with improvement: Improvement) throws -> Player {
        guard (0 ..< improvements.count).contains(slot) else {
            print("Slot \(slot) outside of improvement slot range.")
            throw PlayerError.illegalImprovementSlot
        }
        
        var changedPlayer = self
        changedPlayer.improvements[slot] = improvement
        return changedPlayer
    }
    
    func removeImprovementInSlot(_ slot: Int) throws -> Player {
        guard (0 ..< improvements.count).contains(slot) else {
            print("Slot \(slot) outside of improvement slot range.")
            throw PlayerError.illegalImprovementSlot
        }
        
        var changedPlayer = self
        changedPlayer.improvements.remove(at: slot)
        return changedPlayer
    }
    
    public func sellImprovement(_ improvement: Improvement) throws -> Player {
        guard completedImprovements.contains(improvement) else {
            throw Improvement.ImprovementError.improvementIncomplete
        }
        
        if let slot = improvements.firstIndex(of: improvement) {
            let changedPlayer = try removeImprovementInSlot(slot)
            return changedPlayer.extraIncome(amount: improvement.cost * IMPROVEMENT_SELL_RATIO)
        } else {
            throw PlayerError.illegalImprovementSlot
        }
    }
    
    public func rushImprovement(_ improvement: Improvement) throws -> Player {
        guard cash >= improvement.cost else {
            throw PlayerError.insufficientFunds
        }
        
        let rushedImprovement = try improvement.rush()
        
        if let slot = self.improvements.firstIndex(where: { existingImprovement in
            existingImprovement == improvement && existingImprovement.isCompleted == false
        }) {
            return try self.replaceImprovementInSlot(slot, with: rushedImprovement)
        }
        
        return self
    }
    
    public func investInTechnology(_ technology: Technology) throws -> Player {
        guard technologyPoints >= technology.cost else {
            throw PlayerError.insufficientTechPoints
        }
        
        guard unlockedTechnologies.contains(technology) == false else {
            throw PlayerError.playerAlreadyUnlockedTechnology
        }
        
        guard technology.playerHasPrerequisitesForTechnology(self) else {
            throw PlayerError.playerMissesPrerequisiteTechnology
        }
        
        var changedPlayer = self
        changedPlayer.unlockedTechnologyNames.append(technology.shortName)
        changedPlayer.technologyPoints -= technology.cost
        return changedPlayer
    }
    
    public func technologyToCash(techPoints amount: Double) throws -> Player {
        guard cash >= amount else {
            throw PlayerError.insufficientTechPoints
        }
        
        let cashValue = amount * TECH_TO_CASH_CONVERSION_RATE
        
        var changedPlayer = self
        changedPlayer.cash += cashValue
        changedPlayer.technologyPoints -= amount
        
        return changedPlayer
    }
    
    mutating public func debug_setCash(_ amount: Double) {
        self.cash = amount
    }
    
    mutating public func debug_setTech(_ amount: Double) {
        self.technologyPoints = amount
    }
}

extension Player: Migration { }

// Database aware actions for Player model
extension Player {
    public static func createUser(emailAddress: String, name: String, startImprovementShortName: Improvement.ShortName = .TechConsultancy, on conn: DatabaseConnectable) -> Future<Result<Player, PlayerError>> {
        let player = Player(emailAddress: emailAddress, name: name, startImprovementShortName: startImprovementShortName)
        do {
            try player.validate()
            
            return Player.query(on: conn).filter(\.emailAddress, .equal, emailAddress).first().flatMap(to: Result<Player, PlayerError>.self) { existingUser in
                if existingUser != nil {
                    return Future.map(on: conn) { () -> Result<Player, PlayerError> in
                        return .failure(.userAlreadyExists)
                    }
                }
                
                return player.save(on: conn).map(to: Result<Player, PlayerError>.self) { player in
                    return .success(player)
                }
            }
        } catch {
            return Future.map(on: conn) { return .failure(.usernameFailedValidation) }
        }
    }
    
    // refactor to use Result type. This now shows a very ugly error message when function throws (which might not be an issue at this time).
    public func getSupportedMission(on conn: DatabaseConnectable) throws -> Future<Result<Mission, Error>> {
        if let missionID = ownsMissionID {
            return Mission.find(missionID, on: conn).map(to: Result<Mission, Error>.self) { mission in
                if let mission = mission {
                    return .success(mission)
                } else {
                    return .failure(Mission.MissionError.missionNotFound)
                }
            }
        } else if supportsPlayerID != nil {
            return try getSupportedPlayer(on: conn).flatMap(to: Result<Mission, Error>.self) { supportedPlayer in
                guard let supportedPlayer = supportedPlayer else {
                    return Future.map(on: conn) { () -> Result<Mission, Error> in
                        return .failure(PlayerError.playerNotFound)
                    }
                }
                guard let missionID = supportedPlayer.ownsMissionID else {
                    throw PlayerError.noMission
                }
                return Mission.find(missionID, on: conn).map(to: Result<Mission, Error>.self) { mission in
                    if let mission = mission {
                        return .success(mission)
                    } else {
                        return .failure(Mission.MissionError.missionNotFound)
                    }
                }
            }
        } else {
            return Future.map(on: conn) { return .failure(PlayerError.noMission) }
        }
    }
    
    public func getSupportedPlayer(on conn: DatabaseConnectable) throws -> Future<Player?> {
        guard let playerID = supportsPlayerID else {
            throw PlayerError.noSupportedPlayer
        }
        
        return Player.find(playerID, on: conn)
    }
    
    public func donateToPlayerSupportingSameMission(cash amount: Double, receivingPlayer: Player, on conn: DatabaseConnectable) throws ->
        Future<Result<(donatingPlayer: Player, receivingPlayer: Player), Error>> {
            return try getSupportedMission(on: conn).flatMap(to: Result<(donatingPlayer: Player, receivingPlayer: Player), Error>.self) { missionResult in
                switch missionResult {
                case .success(let mission):
                    return try mission.getSupportingPlayers(on: conn).flatMap(to: Result<(donatingPlayer: Player, receivingPlayer: Player), Error>.self) { supportingPlayers in
                        guard supportingPlayers.contains(where: { player in
                            player.id == self.id }) && supportingPlayers.contains(where: { player in
                                player.id == receivingPlayer.id }) else {
                            return Future.map(on: conn) {
                                return .failure(PlayerError.playersNotInSameMission)
                            }
                        }
                        
                        var result: Result<(donatingPlayer: Player, receivingPlayer: Player), Error>
                        do {
                            let donatingResult = try self.donate(cash: amount, to: receivingPlayer)
                            result = .success(donatingResult)
                        } catch {
                            result = .failure(error)
                        }
                        return Future.map(on: conn) { return result }
                    }
                case .failure(let error):
                    return Future.map(on: conn) {
                        return .failure(error)
                    }
                }
            }
    }
    
    public func donateToPlayerSupportingSameMission(tech amount: Double, receivingPlayer: Player, on conn: DatabaseConnectable) throws ->
        Future<Result<(donatingPlayer: Player, receivingPlayer: Player), Error>> {
            return try getSupportedMission(on: conn).flatMap(to: Result<(donatingPlayer: Player, receivingPlayer: Player), Error>.self) { missionResult in
                switch missionResult {
                case .success(let mission):
                    return try mission.getSupportingPlayers(on: conn).flatMap(to: Result<(donatingPlayer: Player, receivingPlayer: Player), Error>.self) { supportingPlayers in
                        guard supportingPlayers.contains(where: { player in
                            player.id == self.id }) && supportingPlayers.contains(where: { player in
                                player.id == receivingPlayer.id }) else {
                            return Future.map(on: conn) {
                                return .failure(PlayerError.playersNotInSameMission)
                            }
                        }
                        
                        var result: Result<(donatingPlayer: Player, receivingPlayer: Player), Error>
                        do {
                            let donatingResult = try self.donate(techPoints: amount, to: receivingPlayer)
                            result = .success(donatingResult)
                        } catch {
                            result = .failure(error)
                        }
                        return Future.map(on: conn) { return result }
                    }
                case .failure(let error):
                    return Future.map(on: conn) {
                        return .failure(error)
                    }
                }
            }
    }
    
    public func investInComponent(_ component: Component, on conn: DatabaseConnectable, date: Date) throws -> Future<Result<(changedPlayer: Player, changedMission: Mission), Error>> {
        return try getSupportedMission(on: conn).flatMap(to: Result<(changedPlayer: Player, changedMission: Mission), Error>.self) { missionResult in
            
            switch missionResult {
            case .success(let mission):
                var result: Result<(changedPlayer: Player, changedMission: Mission), Error>
                do {
                    let investResult = try self.investInComponent(component, in: mission, date: date)
                    result = .success(investResult)
                } catch {
                    if let error = error as? PlayerError {
                        result = .failure(error)
                    } else {
                        throw error
                    }
                }
                return Future.map(on: conn) { return result }
            
            case .failure(let error):
                return Future.map(on: conn) {
                    return .failure(error)
                }
            }
        }
    }
    
    public static func savePlayers(_ players: [Player], on conn: DatabaseConnectable) -> Future<[Player]> {
        let futures = players.map { player in
            return player.update(on: conn)
        }
        return futures.flatten(on: conn)
    }
}

extension Player: Parameter { }

extension Player: Validatable {
    /// See `Validatable`.
    public static func validations() throws -> Validations<Player> {
        var validations = Validations(Player.self)
        try validations.add(\.emailAddress, .email)
        try validations.add(\.name, .count(3...) && .ascii)
        return validations
    }
}

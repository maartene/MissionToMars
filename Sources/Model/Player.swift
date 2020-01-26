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
    public private(set) var cash: Double = 250_000
    public private(set) var technologyPoints: Double = 75
        
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
        if let completedStartImprovement = try? startImprovement.startBuild(startDate: Date()).updateImprovement(ticks: startImprovement.buildTime) {
            assert(completedStartImprovement.isCompleted, "Your starting tech consultancy firm should be complete.")
            self.improvements = [completedStartImprovement]
        }
        
        self.unlockedTechnologyNames = [Technology.ShortName.LiIonBattery]
    }
    
    var completedImprovements: [Improvement] {
        return improvements.filter { improvement in
            return improvement.isCompleted
        }
    }
    
    var buildTimeFactor: Double {
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
    }
    
    var componentDiscount: Double {
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
    }
    
    var componentBuildTimeFactor: Double {
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
    }
    
    public func updatePlayer(ticks: Int = 1) -> Player {
        var updatedPlayer = self
        
        for _ in 0 ..< ticks {
            //updatedPlayer.cash += cashPerTick
            //updatedPlayer.technologyPoints += 7
            
            let updatedImprovements = updatedPlayer.improvements.map { improvement in
                return improvement.updateImprovement(buildTimeFactor: buildTimeFactor)}
            updatedPlayer.improvements = updatedImprovements
            
            for improvement in updatedPlayer.improvements {
                updatedPlayer = improvement.applyEffectForOwner(player: updatedPlayer)
            }
        }
        
        //print("cashPerTick: \(cashPerTick)")
        //print(updatedPlayer)
        return updatedPlayer
    }
    
    public var cashPerTick: Double {
        let allEffects = completedImprovements.map { improvement in
            return improvement.updateEffects
            }.joined()
        
        let flatIncomePerTick = allEffects.reduce(0.0) { result, effect in
            switch effect {
            case .extraIncomeFlat(let amount):
                return result + amount
            default:
                return result
            }
        }
        
        let interestPerTick = allEffects.reduce(0.0) { result, effect in
            switch effect {
            case .extraIncomePercentage(let percentage):
                return result + (percentage / 100.0)
            default:
                return result
            }
        }
        
        return flatIncomePerTick + cash * interestPerTick
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
    
    func donate(cash amount: Double, to player: Player) throws -> (donatingPlayer: Player, receivingPlayer: Player) {
        guard amount <= self.cash else {
            throw PlayerError.insufficientFunds
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
        
        let netCost = component.cost * componentDiscount
        
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
        guard improvements.contains(improvement) == false else {
            throw PlayerError.playerAlreadyHasImprovement
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
    
    func removeImprovement(_ improvement: Improvement) -> Player {
        var changedPlayer = self
        
        if let index = changedPlayer.improvements.firstIndex(of: improvement) {
            _ = changedPlayer.improvements.remove(at: index)
            //print("removing \()")
        }
        assert(changedPlayer.improvements.contains(improvement) == false)
        return changedPlayer
    }
    
    func removeImprovement(_ shortName: Improvement.ShortName) -> Player {
        guard let improvement = Improvement.getImprovementByName(shortName) else {
            return self
        }
        
        return removeImprovement(improvement)
    }
    
    public func rushImprovement(_ improvement: Improvement) throws -> Player {
        guard cash >= improvement.cost else {
            throw PlayerError.insufficientFunds
        }
        
        var changedPlayer = self
        
        let rushedImprovement = try improvement.rush()
        
        changedPlayer = changedPlayer.removeImprovement(improvement)
        changedPlayer.improvements.append(rushedImprovement)
        
        assert(changedPlayer.improvements.contains(improvement))
        return changedPlayer
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
    
    @available(*, deprecated, message: "Use donateToPlayerSupportingSameMission(cash: receivingPlayer: on:) instead")
    public func donateToSupportedPlayer(cash amount: Double, on conn: DatabaseConnectable) throws -> Future<Result<(donatingPlayer: Player, receivingPlayer: Player), Error>> {
        return try getSupportedPlayer(on: conn).flatMap(to: Result<(donatingPlayer: Player, receivingPlayer: Player), Error>.self) { player in
            guard let supportedPlayer = player else {
                return Future.map(on: conn) {
                    return .failure(PlayerError.noSupportedPlayer)
                }
            }
            
            var result: Result<(donatingPlayer: Player, receivingPlayer: Player), Error>
            do {
                let donatingResult = try self.donate(cash: amount, to: supportedPlayer)
                result = .success(donatingResult)
            } catch {
                result = .failure(error)
            }
            return Future.map(on: conn) { return result }
        }
    }
    
    @available(*, deprecated, message: "Use donateToPlayerSupportingSameMission(tech: receivingPlayer: on:) instead")
    public func donateToSupportedPlayer(techPoints amount: Double, on conn: DatabaseConnectable) throws -> Future<Result<(donatingPlayer: Player, receivingPlayer: Player), Error>> {
        return try getSupportedPlayer(on: conn).flatMap(to: Result<(donatingPlayer: Player, receivingPlayer: Player), Error>.self) { player in
            guard let supportedPlayer = player else {
                return Future.map(on: conn) {
                    return .failure(PlayerError.noSupportedPlayer)
                }
            }
            
            var result: Result<(donatingPlayer: Player, receivingPlayer: Player), Error>
            do {
                let donatingResult = try self.donate(techPoints: amount, to: supportedPlayer)
                result = .success(donatingResult)
            } catch {
                result = .failure(error)
            }
            return Future.map(on: conn) { return result }
        }
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
                                return .failure(PlayerError.noSupportedPlayer)
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
                                return .failure(PlayerError.noSupportedPlayer)
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

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
    }
    
    public var id: UUID?
    
    public let username: String
    
    public var ownsMissionID: UUID?
    public var supportsPlayerID: UUID?
    
    public private(set) var unlockedTechnologyNames: [Technology.ShortName]
    public var unlockedTechnologies: [Technology] {
        return unlockedTechnologyNames.compactMap { techName in
            return Technology.getTechnologyByName(techName)
        }
    }
    
    // resources
    public private(set) var cash: Double = 1000
    public private(set) var technologyPoints: Double = 75
    
    @available(*, deprecated, message: "This is the old technology system, which is now deprecated.")
    public private(set) var technologyLevel: Int = 1
    
    public private(set) var improvements: [Improvement]
    
    public init(username: String) {
        self.username = username
        self.improvements = []
        
        let techConsultancy = Improvement.getImprovementByName(.TechConsultancy)!
        if let completedConsultancy = try? techConsultancy.startBuild(startDate: Date()).updateImprovement(ticks: techConsultancy.buildTime) {
            assert(completedConsultancy.isCompleted, "Your starting tech consultancy firm should be complete.")
            self.improvements = [completedConsultancy]
        }
        
        self.unlockedTechnologyNames = [Technology.ShortName.AutonomousDriving]
    }
    
    public func updatePlayer(ticks: Int = 1) -> Player {
        var updatedPlayer = self
        
        for _ in 0 ..< ticks {
            updatedPlayer.cash += cashPerTick
            updatedPlayer.technologyPoints += 7
            
            let updatedImprovements = updatedPlayer.improvements.map { improvement in
                return improvement.updateImprovement()}
            updatedPlayer.improvements = updatedImprovements
            
            for improvement in updatedPlayer.improvements {
                updatedPlayer = improvement.applyEffectForOwner(player: updatedPlayer)
            }
        }
        
        return updatedPlayer
    }
    
    @available(*, deprecated, message: "This uses the old technology system, which is now deprecated.")
    public var cashPerTick: Double {
        return 5_000.0 * myPow(base: 1.5, exponent: technologyLevel)
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
        
        guard cash >= component.cost else {
            throw PlayerError.insufficientFunds
        }
        
        updatedMission = try updatedMission.startBuildingInStage(component, buildDate: date)
        updatedPlayer.cash -= component.cost
        
        return (updatedPlayer, updatedMission)
    }
    
    @available(*, deprecated, message: "This is the old technology system, which is now deprecated.")
    public var costOfNextTechnologyLevel: Double {
        return 40.0 * myPow(base: 1.6, exponent: technologyLevel)
    }
    
    @available(*, deprecated, message: "This is the old technology system, which is now deprecated.")
    public func investInNextLevelOfTechnology() throws -> Player {
        //print("Required tech points for next level: \(costOfNextTechnologyLevel)")
        guard costOfNextTechnologyLevel <= self.technologyPoints else {
            throw PlayerError.insufficientTechPoints
        }
        
        var changedPlayer = self
        
        changedPlayer.technologyPoints -= costOfNextTechnologyLevel
        changedPlayer.technologyLevel += 1
        
        return changedPlayer
    }
    
    public func startBuildImprovement(_ improvement: Improvement, startDate: Date) throws -> Player {
        guard improvements.contains(improvement) == false else {
            throw PlayerError.playerAlreadyHasImprovement
        }
        
        guard cash >= improvement.cost else {
            throw PlayerError.insufficientFunds
        }
        
        let buildingImprovement = try improvement.startBuild(startDate: startDate)
        
        var changedPlayer = self
        
        changedPlayer.improvements.append(buildingImprovement)
        assert(improvement.percentageCompleted == 0)
        changedPlayer.cash -= improvement.cost
        
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
}

extension Player: Migration { }

// Database aware actions for Player model
extension Player {
    public static func createUser(username: String, on conn: DatabaseConnectable) -> Future<Result<Player, PlayerError>> {
        let player = Player(username: username)
        do {
            try player.validate()
            
            return Player.query(on: conn).filter(\.username, .equal, username).first().flatMap(to: Result<Player, PlayerError>.self) { existingUser in
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
    
    public func getSupportedMission(on conn: DatabaseConnectable) throws -> Future<Mission?> {
        guard let missionID = ownsMissionID else {
            throw PlayerError.noMission
        }
        
        return Mission.find(missionID, on: conn)
    }
    
    public func getSupportedPlayer(on conn: DatabaseConnectable) throws -> Future<Player?> {
        guard let playerID = supportsPlayerID else {
            throw PlayerError.noSupportedPlayer
        }
        
        return Player.find(playerID, on: conn)
    }
    
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
    
    public func investInComponent(_ component: Component, on conn: DatabaseConnectable, date: Date) throws -> Future<Result<(changedPlayer: Player, changedMission: Mission), PlayerError>> {
        return try getSupportedMission(on: conn).flatMap(to: Result<(changedPlayer: Player, changedMission: Mission), PlayerError>.self) { mission in
            guard let changedMission = mission else {
                return Future.map(on: conn) {
                    return .failure(PlayerError.noMission)
                }
            }
            
            var result: Result<(changedPlayer: Player, changedMission: Mission), PlayerError>
            do {
                let investResult = try self.investInComponent(component, in: changedMission, date: date)
                result = .success(investResult)
            } catch {
                if let error = error as? PlayerError {
                    result = .failure(error)
                } else {
                    throw error
                }
            }
            return Future.map(on: conn) { return result }
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
        try validations.add(\.username, .count(3...) && .alphanumeric)
        return validations
    }
}

func myPow(base: Double, exponent: Int) -> Double {
    var result = 1.0
    for _ in 0 ..< exponent {
        result *= base
    }
    return result
}

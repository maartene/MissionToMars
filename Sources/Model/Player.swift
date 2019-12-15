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
    public enum PlayerError: Error, Debuggable {
        public var identifier: String {
            switch self {
            case .userAlreadyExists:
                return "userAlreadyExists"
            default:
                return "some other error"
            }
            
        }
        
        public var reason: String {
            switch self {
            case .userAlreadyExists:
                return "A user with this username already exists."
            default:
                return "some other error"
            }
        }
        
        
        
        
        
        case noMission
        case insufficientFunds
        case insufficientTechPoints
        case noSupportedPlayer
        case userAlreadyExists
    }
    
    public var id: UUID?
    
    public let username: String
    
    public var ownsMissionID: UUID?
    public var supportsPlayerID: UUID?
    
    // resources
    public private(set) var cash: Double = 1000
    public private(set) var technologyPoints: Double = 75
    
    public private(set) var technologyLevel: Int = 1
    
    //var improvements = [Improvement]()
    
    public init(username: String) {
        self.username = username
    }
    
    public func update(ticks: Int = 1) -> Player {
        var updatedPlayer = self
        
        for _ in 0 ..< ticks {
            updatedPlayer.cash += 100
            updatedPlayer.technologyPoints += 3
        }
        
        return updatedPlayer
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
    
    func investInMission(amount: Double, in mission: Mission) throws -> (changedPlayer: Player, changedMission: Mission) {
        var changedMission = mission
        var changedPlayer = self
            
        guard amount <= self.cash else {
            throw PlayerError.insufficientFunds
        }
        
        changedPlayer.cash -= amount
        
        let missionPoints = self.missionPointValue(for: amount)
        //print("Adding mission points: \(missionPoints)")
        changedMission.percentageDone += missionPoints
        
        return (changedPlayer, changedMission)
    }
    
    public var costOfNextTechnologyLevel: Double {
        40.0 * NSDecimalNumber(decimal: pow(1.6, technologyLevel)).doubleValue
    }
    
    public var technologyMissionPointDiscount: Double {
        100 * NSDecimalNumber(decimal: pow(1.5, technologyLevel)).doubleValue
    }
    
    public func investInNextLevelOfTechnology() throws -> Player {
        //print("Required tech points for next level: \(costOfNextTechnologyLevel)")
        guard costOfNextTechnologyLevel <= self.technologyPoints else {
            throw PlayerError.insufficientFunds
        }
        
        var changedPlayer = self
        
        changedPlayer.technologyPoints -= costOfNextTechnologyLevel
        changedPlayer.technologyLevel += 1
        
        return changedPlayer
    }
    
    public func missionPointValue(for cashAmount: Double) -> Double {
        return cashAmount / Double(1_000_000 - technologyMissionPointDiscount)
    }
}

extension Player: Migration { }

// Database aware actions for Player model
extension Player {
    public static func createUser(username: String, on conn: DatabaseConnectable) -> Future<Result<Player, PlayerError>> {
        return Player.query(on: conn).filter(\.username, .equal, username).first().flatMap(to: Result<Player, PlayerError>.self) { existingUser in
            if existingUser != nil {
                return Future.map(on: conn) { () -> Result<Player, PlayerError> in
                    return .failure(.userAlreadyExists)
                }
            }
            
            let player = Player(username: username)
            
            return player.save(on: conn).map(to: Result<Player, PlayerError>.self) { player in
                return .success(player)
            }
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
    
    public func investInMission(amount: Double, on conn: DatabaseConnectable) throws -> Future<Result<(changedPlayer: Player, changedMission: Mission), PlayerError>> {
        return try getSupportedMission(on: conn).flatMap(to: Result<(changedPlayer: Player, changedMission: Mission), PlayerError>.self) { mission in
            guard let changedMission = mission else {
                return Future.map(on: conn) {
                    return .failure(PlayerError.noMission)
                }
            }
            
            var result: Result<(changedPlayer: Player, changedMission: Mission), PlayerError>
            do {
                let investResult = try self.investInMission(amount: amount, in: changedMission)
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
}

extension Player: Parameter { }

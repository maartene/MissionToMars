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
    public static func createUser(username: String, on conn: DatabaseConnectable) throws -> Future<Player> {
        return Player.query(on: conn).filter(\.username, .equal, username).first().flatMap(to: Player.self) { existingUser in
            if existingUser != nil {
                throw PlayerError.userAlreadyExists
            }
            
            let player = Player(username: username)
            
            return player.save(on: conn)
        }
    }
    
    func getSupportedMission(on conn: DatabaseConnectable) throws -> Future<Mission?> {
        guard let missionID = ownsMissionID else {
            throw PlayerError.noMission
        }
        
        return Mission.find(missionID, on: conn)
    }
    
    func getSupportedPlayer(on conn: DatabaseConnectable) throws -> Future<Player?> {
        guard let playerID = supportsPlayerID else {
            throw PlayerError.noSupportedPlayer
        }
        
        return Player.find(playerID, on: conn)
    }
    
    public func donateToSupportedPlayer(cash amount: Double, on conn: DatabaseConnectable) throws -> Future<(donatingPlayer: Player, receivingPlayer: Player)> {
        return try getSupportedPlayer(on: conn).map(to: (donatingPlayer: Player, receivingPlayer: Player).self) { player in
            guard let supportedPlayer = player else {
                throw PlayerError.noSupportedPlayer
            }
            
            return try self.donate(cash: amount, to: supportedPlayer)
        }
    }
    
    public func donateToSupportedPlayer(techPoints amount: Double, on conn: DatabaseConnectable) throws -> Future<(donatingPlayer: Player, receivingPlayer: Player)> {
        return try getSupportedPlayer(on: conn).map(to: (donatingPlayer: Player, receivingPlayer: Player).self) { player in
            guard let supportedPlayer = player else {
                throw PlayerError.noSupportedPlayer
            }
            
            return try self.donate(techPoints: amount, to: supportedPlayer)
        }
    }
    
    public func investInMission(amount: Double, on conn: DatabaseConnectable) throws -> Future<(changedPlayer: Player, changedMission: Mission)> {
        return try getSupportedMission(on: conn).map(to: (changedPlayer: Player, changedMission: Mission).self) { mission in
            guard let changedMission = mission else {
                throw PlayerError.noMission
            }
            
            return try self.investInMission(amount: amount, in: changedMission)
        }
    }
}

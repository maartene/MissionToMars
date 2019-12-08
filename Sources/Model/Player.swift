//
//  Player.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation

struct Player {
    enum PlayerError: Error {
        case noMissionError
        case insufficientFunds
        case insufficientTechPoints
    }
    
    var id: UUID?
    
    let username: String
    
    var ownsMission: Mission?
    var supportsMission: Mission?
    
    // resources
    var cash: Double = 1000
    var technologyPoints: Double = 75
    
    var technologyLevel: Int = 1
    
    //var improvements = [Improvement]()
    
    func update(ticks: Int = 1) -> Player {
        var updatedPlayer = self
        
        for _ in 0 ..< ticks {
            updatedPlayer.cash += 100
            updatedPlayer.technologyPoints += 3
            
            /*let updatedImprovements = improvements.map {
                $0.update()
            }
            
            updatedPlayer.improvements = updatedImprovements*/
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
    
    func investInMission(amount: Double) throws -> Player {
        guard var changedMission = self.ownsMission else {
            throw PlayerError.noMissionError
        }
        
        var changedPlayer = self
        
        guard amount <= cash else {
            throw PlayerError.insufficientFunds
        }
        
        changedPlayer.cash -= amount
        
        let missionPoints = missionPointValue(for: amount)
        print("Adding mission points: \(missionPoints)")
        changedMission.percentageDone += missionPoints
        
        changedPlayer.ownsMission = changedMission
        
        return changedPlayer
    }
    
    var costOfNextTechnologyLevel: Double {
        40.0 * pow(1.5, technologyLevel).doubleValue
    }
    
    func investInNextLevelOfTechnology() throws -> Player {
        print("Required tech points for next level: \(costOfNextTechnologyLevel)")
        guard costOfNextTechnologyLevel <= self.technologyPoints else {
            throw PlayerError.insufficientFunds
        }
        
        var changedPlayer = self
        
        changedPlayer.technologyPoints -= costOfNextTechnologyLevel
        changedPlayer.technologyLevel += 1
        
        return changedPlayer
    }
    
    func missionPointValue(for cashAmount: Double) -> Double {
        return cashAmount / Double(1_000_000 - technologyLevel * 100)
    }
}

extension Decimal {
    var doubleValue:Double {
        return NSDecimalNumber(decimal:self).doubleValue
    }
}

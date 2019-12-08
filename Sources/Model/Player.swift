//
//  Player.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation

struct Player {
    var id: UUID?
    
    let username: String
    
    var ownsMission: Mission?
    var supportsMission: Mission?
    
    // resources
    var cash: Double = 1000
    var technology: Double = 50
    
    var improvements = [Improvement]()
    
    func update(ticks: Int = 1) -> Player {
        var updatedPlayer = self
        
        for _ in 0 ..< ticks {
            updatedPlayer.cash += 100
            updatedPlayer.technology += 3
            
            let updatedImprovements = improvements.map {
                $0.update()
            }
            
            updatedPlayer.improvements = updatedImprovements
        }
        
        return updatedPlayer
    }
    
    func donate(cash amount: Double, to player: Player) -> (donatingPlayer: Player, receivingPlayer: Player) {
        guard amount <= self.cash else {
            print("Insufficient cash")
            return (self, player)
        }
        
        var receivingPlayer = player
        var donatingPlayer = self
        
        receivingPlayer.cash += amount
        donatingPlayer.cash -= amount
        
        return (donatingPlayer, receivingPlayer)
    }
    
    func donate(technology amount: Double, to player: Player) -> (donatingPlayer: Player, receivingPlayer: Player) {
        guard amount <= self.technology else {
            print("Insufficient technology")
            return (self, player)
        }
        
        var receivingPlayer = player
        var donatingPlayer = self
        
        receivingPlayer.technology += amount
        donatingPlayer.technology -= amount
        
        return (donatingPlayer, receivingPlayer)
    }
}

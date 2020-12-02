//
//  File.swift
//  
//
//  Created by Maarten Engels on 26/11/2020.
//

import Foundation

public struct ActivatedAbility: Codable {
    enum ActivatedAbilityErrors: Error {
        case cannotActivate
    }
    
    let name: String
    let effects: [Effect]
    let cooldown: TimeInterval // Cooldown in seconds
    var lastActivation: Date?
    
    var canTrigger: Bool {
        if let lastActivation = lastActivation {
            return lastActivation.addingTimeInterval(cooldown) <= Date()
        } else {
            return true
        }
    }
    
    func trigger(_ player: Player) throws -> (updatedAbility: ActivatedAbility, updatedPlayer: Player) {
        guard canTrigger else {
            throw ActivatedAbilityErrors.cannotActivate
        }
        
        var updatedAbility = self
        updatedAbility.lastActivation = Date()
        
        var updatedPlayer = player
        
        for effect in self.effects {
            updatedPlayer = effect.applyEffectToPlayer(updatedPlayer)
        }
        
        return (updatedAbility, updatedPlayer)
    }
    
    var description: String {
        var result = ""
        
        for effect in effects {
            result += effect.description + "\n"
        }
        
        result += "Cooldown: \(cooldown)s"
        
        return result
    }
    
    var cooldownDone: Double {
        if canTrigger {
            return 1
        }
        
        let distance = abs(Date().timeIntervalSince(lastActivation ?? Date()))
        return distance / cooldown
    }
}

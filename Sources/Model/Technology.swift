//
//  Technology.swift
//  App
//
//  Created by Maarten Engels on 30/12/2019.
//

import Foundation

// Technology effects are instantanious (once you have enough technology points to buy them)
public struct Technology: Equatable, Codable {
    
    public enum ShortName: Int, Codable {
        case AutonomousDriving
        case AdvancedRocketry
        case RadiationShielding
        case RecoverableAI
    }
    
    public static let allTechnologies = [
        Technology(shortName: .AdvancedRocketry, name: "Advanced Rocketry", description: "Lorem Ipsum", cost: 50, prerequisites: [.RecoverableAI]),
        Technology(shortName: .RadiationShielding, name: "Cosmic Radiationg Shielding", description: "Lorem ipsum", cost: 75, prerequisites: []),
        Technology(shortName: .RecoverableAI, name: "Recoverable AI", description: "Lorem ipsum", cost: 50, prerequisites: []),
        Technology(shortName: .AutonomousDriving, name: "Autonomous Driving (terristrial)", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.", cost: 100, prerequisites: [])
    ]
    
    public static func getTechnologyByName(_ shortName: ShortName) -> Technology? {
        return allTechnologies.first(where: { technology in technology.shortName == shortName })
    }
    
    public static func == (lhs: Technology, rhs: Technology) -> Bool {
        return lhs.shortName == rhs.shortName
    }
    
    public let shortName: ShortName
    public let name: String
    public let description: String
    public let cost: Double                           // in tech points
    public let prerequisites: [ShortName]
    
    public func playerHasPrerequisitesForTechnology(_ player: Player) -> Bool {
        for prereq in prerequisites {
            if player.unlockedTechnologyNames.contains(prereq) == false {
                return false
            }
        }
        
        // all prerequisites met.
        return true
    }
    
    public static func unlockableTechnologiesForPlayer(_ player: Player) -> [Technology] {
        return allTechnologies.filter { technology in
            return player.unlockedTechnologyNames.contains(technology.shortName) == false &&
            technology.playerHasPrerequisitesForTechnology(player)
        }
    }
}

//
//  Technology.swift
//  App
//
//  Created by Maarten Engels on 30/12/2019.
//

import Foundation

// Technology effects are instantanious (once you have enough technology points to buy them)
struct Technology: Equatable {
    
    enum ShortName: String, Codable {
        case AutonomousDriving
        case AdvancedRocketry
        case RadiationShielding
        case RecoverableAI
    }
    
    static let allTechnologies = [
        Technology(shortName: .AdvancedRocketry, name: "Advanced Rocketry", description: "Lorem Ipsum", cost: 50, prerequisites: [.RecoverableAI]),
        Technology(shortName: .RadiationShielding, name: "Cosmic Radiationg Shielding", description: "Lorem ipsum", cost: 75, prerequisites: []),
        Technology(shortName: .RecoverableAI, name: "Recoverable AI", description: "Lorem ipsum", cost: 50, prerequisites: []),
        Technology(shortName: .AutonomousDriving, name: "Autonomous Driving (terristrial)", description: "Lorem ipsum", cost: 100, prerequisites: [])
    ]
    
    public static func getTechnologyByName(_ shortName: ShortName) -> Technology? {
        return allTechnologies.first(where: { technology in technology.shortName == shortName })
    }
    
    public static func == (lhs: Technology, rhs: Technology) -> Bool {
        return lhs.shortName == rhs.shortName
    }
    
    let shortName: ShortName
    let name: String
    let description: String
    let cost: Int                           // in tech points
    let prerequisites: [ShortName]
}

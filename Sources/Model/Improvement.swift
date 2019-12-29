//
//  Improvement.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation
import Vapor

public struct Improvement: Codable, Equatable {
    public enum ImprovementError: Error {
        case componentAlreadyBeingBuilt
        
    }
    
    public enum ShortName: Int, CaseIterable, Codable {
        case TechConsultancy
        case Faculty
        case SpaceTourism
    }
    
    public static let allImprovements = [
        Improvement(shortName: .TechConsultancy, name: "Technology Consultancy firm", description: "This firm is the bread and butter of your company. It keeps you 'in the black' while you pertake in the mission and pursue other endeavors.\nCreates both extra technologypoints (+1), as well as a little extra income (+500). You start with this.", cost: 1_000_000, buildTime: 365 / 6),
        Improvement(shortName: .Faculty, name: "Faculty of Applied Sciences", description: "Buy yourself a faculty on a prestigious University and assure yourself of a steady supply of extra technology points (+5)", cost: 250_000, buildTime: 365 / 12),
        Improvement(shortName: .SpaceTourism, name: "Space Tourism Agency", description: "Allow the rich the opportunity to look at Earth from Space! As you are piggy backing on your existing technology, this is a very cost effective way of generating some extra income (+1k)", cost: 100_000, buildTime: 365 / 12),
    ]
    
    public static func getImprovementByName(_ shortName: ShortName) -> Improvement? {
        return allImprovements.first(where: { i in i.shortName == shortName })
    }
    
    public static func == (lhs: Improvement, rhs: Improvement) -> Bool {
        return lhs.shortName == rhs.shortName
    }
    
    public let shortName: ShortName
    public let name: String
    var updateEffectForPlayer: (Player) -> (Player) {
        switch shortName {
        case .TechConsultancy:
            return { player in
                return player.extraIncome(amount: 500).extraTech(amount: 1)
            }
        case .Faculty:
            return { player in return player.extraTech(amount: 5) }
        case .SpaceTourism:
            return { player in return player.extraIncome(amount: 1000) }
        default:
            return { player in return player }
        }
    }
    
    public let description: String
    public let cost: Double
    public let buildTime: Int // in days/ticks
    public private(set) var buildStartedOn: Date?
    public private(set) var percentageCompleted: Double = 0
    
    public var isCompleted: Bool {
        return percentageCompleted >= 100
    }
    
    public func startBuild(startDate: Date) throws -> Improvement {
        guard buildStartedOn == nil else {
            throw ImprovementError.componentAlreadyBeingBuilt
        }
        
        var startedBuiltImprovement = self
        startedBuiltImprovement.buildStartedOn = startDate
        return startedBuiltImprovement
    }
    
    public func updateImprovement(ticks: Int = 1) -> Improvement {
        var changedImprovement = self
        
        if buildStartedOn != nil {
            changedImprovement.percentageCompleted += 100.0 * Double(ticks) / Double(buildTime)
        }
        
        if changedImprovement.percentageCompleted > 100.0 {
            changedImprovement.percentageCompleted = 100.0
        }
        
        return changedImprovement
    }
    
    public func applyEffectForOwner(player: Player) -> Player {
        guard isCompleted else {
            print("Improvement \(name) owned by player \(player.username) is not yet complete.")
            return player
        }
        
        return updateEffectForPlayer(player)
    }
    
    
    
    
}

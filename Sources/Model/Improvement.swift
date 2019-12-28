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
        case Factory
        case Mill
        case Mine
        case Mouse
    }
    
    public static let allImprovements = [
        Improvement(shortName: .TechConsultancy, name: "Technology Consultancy firm", description: "This firm is the bread and butter of your company. It keeps you 'in the black' while you pertake in the mission and pursue other endeavors.\nCreates both extra technologypoints (+1), as well as a little extra income (+500). You start with this.", cost: 1_000_000, buildTime: 365 / 6),
        Improvement(shortName: .Factory, name: "Factory", description: "Some factory", cost: 1_000_000, buildTime: 365 / 6),
        Improvement(shortName: .Mill, name: "Factory 2", description: "Some factory", cost: 1_000, buildTime: 365 / 6),
        Improvement(shortName: .Mine, name: "Factory 3", description: "Some factory", cost: 10_000, buildTime: 365 / 6),
        Improvement(shortName: .Mouse, name: "Factory 4", description: "Some factory", cost: 100_000, buildTime: 365 / 6),
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
            case .Factory:
                return { player in return player.extraIncome(amount: player.cashPerTick * 0.75) }
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

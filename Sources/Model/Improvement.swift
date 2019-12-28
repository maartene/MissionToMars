//
//  Improvement.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation
import Vapor

struct Improvement: Codable, Equatable {
    public enum ImprovementError: Error {
        case componentAlreadyBeingBuilt
        
    }
    
    static let allImprovements = [Improvement(shortName: .Factory, name: "Factory", description: "Some factory", cost: 1_000_000, buildTime: 365 / 6)
    ]
    
    public static func getImprovementByName(_ shortName: ShortName) -> Improvement? {
        return allImprovements.first(where: { i in i.shortName == shortName })
    }
    
    public static func == (lhs: Improvement, rhs: Improvement) -> Bool {
        return lhs.shortName == rhs.shortName
    }
    
    public enum ShortName: String, CaseIterable, Codable {
        case Factory
    }
    
    public let shortName: ShortName
    public let name: String
    var updateEffectForPlayer: (Player) -> (Player) {
        switch shortName {
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
    
    public func applyEffectForOwner(player: Player, ticks: Int = 1) -> Player {
        guard isCompleted else {
            print("Improvement \(name) owned by player \(player.username) is not yet complete.")
            return player
        }
        
        var updatedPlayer = player
        for _ in 0 ..< ticks {
            updatedPlayer = updateEffectForPlayer(updatedPlayer)
        }
        return updatedPlayer
    }
    
    
}

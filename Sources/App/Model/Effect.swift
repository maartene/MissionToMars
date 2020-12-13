//
//  Effect.swift
//  App
//
//  Created by Maarten Engels on 11/01/2020.
//

import Foundation

public enum Effect: Codable, CustomStringConvertible {
    
    enum EffectError: Error {
        case decodingUnknownEffectType
    }
    
    enum EffectCodingKeys: CodingKey {
        case effectType
        case value
    }
    
    case extraIncomeFlat(amount: Double)
    case extraTechFlat(amount: Double)
    case interestOnCash(percentage: Double)
    //case extraTechPercentage(percentage: Double)
    case lowerProductionTimePercentage(percentage: Double)
    case extraIncomeDailyIncome(times: Double) // this effect has a risk of recursion. Only use for one-shots!
    case oneShot(shortName: Improvement.ShortName)
    case shortenComponentBuildTime(percentage: Double)
    case componentBuildDiscount(percentage: Double)
    case tagEffectDoubler(tag: Tag)
    case extraBuildPointsFlat(amount: Double)
    case extraComponentBuildPointsFlat(amount: Double)
    case extraActionPointsFlat(amount: Int)
    case extraImprovementSlots(amount: Int)
    case extraMaxActionPoints(amount: Int)
    case extraSpeciliazationSlots(amount: Int)
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: EffectCodingKeys.self)
        let type = try values.decode(String.self, forKey: .effectType)
        switch type {
        case "extraIncomeFlat":
            let amount = try values.decode(Double.self, forKey: .value)
            self = .extraIncomeFlat(amount: amount)
        case "extraTechFlat":
            let amount = try values.decode(Double.self, forKey: .value)
            self = .extraTechFlat(amount: amount)
        case "extraIncomePercentage":
            let percentage = try values.decode(Double.self, forKey: .value)
            self = .interestOnCash(percentage: percentage)
        case "lowerProductionTimePercentage":
            let percentage = try values.decode(Double.self, forKey: .value)
            self = .lowerProductionTimePercentage(percentage: percentage)
        case "extraIncomeDailyIncome":
            let times = try values.decode(Double.self, forKey: .value)
            self = .extraIncomeDailyIncome(times: times)
        case "oneShot":
            let shortName = try values.decode(Improvement.ShortName.self, forKey: .value)
            self = .oneShot(shortName: shortName)
        case "shortenComponentBuildTime":
            let percentage = try values.decode(Double.self, forKey: .value)
            self = .shortenComponentBuildTime(percentage: percentage)
        case "componentBuildDiscount":
            let percentage = try values.decode(Double.self, forKey: .value)
            self = .componentBuildDiscount(percentage: percentage)
        case "tagEffectDoubler":
            let tag = try values.decode(Tag.self, forKey: .value)
            self = .tagEffectDoubler(tag: tag)
        case "extraBuildPointsFlat":
            let amount = try values.decode(Double.self, forKey: .value)
            self = .extraBuildPointsFlat(amount: amount)
        case "extraComponentBuildPointsFlat":
            let amount = try values.decode(Double.self, forKey: .value)
            self = .extraComponentBuildPointsFlat(amount: amount)
        case "extraActionPointsFlat":
            let amount = try values.decode(Int.self, forKey: .value)
            self = .extraActionPointsFlat(amount: amount)
        case "extraImprovementSlots":
            let amount = try values.decode(Int.self, forKey: .value)
            self = .extraImprovementSlots(amount: amount)
        case "extraSpeciliazationSlots":
            let amount = try values.decode(Int.self, forKey: .value)
            self = .extraSpeciliazationSlots(amount: amount)
        case "extraMaxActionPoints":
            let amount = try values.decode(Int.self, forKey: .value)
            self = .extraMaxActionPoints(amount: amount)
        default:
            throw EffectError.decodingUnknownEffectType
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EffectCodingKeys.self)
        switch self {
        case .extraIncomeFlat(let amount):
            try container.encode("extraIncomeFlat", forKey: .effectType)
            try container.encode(amount, forKey: .value)
        case .extraTechFlat(let amount):
            try container.encode("extraTechFlat", forKey: .effectType)
            try container.encode(amount, forKey: .value)
        case .interestOnCash(let percentage):
            try container.encode("extraIncomePercentage", forKey: .effectType)
            try container.encode(percentage, forKey: .value)
        case .lowerProductionTimePercentage(let percentage):
            try container.encode("lowerProductionTimePercentage", forKey: .effectType)
            try container.encode(percentage, forKey: .value)
        case .extraIncomeDailyIncome(let times):
            try container.encode("extraIncomeDailyIncome", forKey: .effectType)
            try container.encode(times, forKey: .value)
        case .oneShot(let shortName):
            try container.encode("oneShot", forKey: .effectType)
            try container.encode(shortName, forKey: .value)
        case .shortenComponentBuildTime(let percentage):
            try container.encode("shortenComponentBuildTime", forKey: .effectType)
            try container.encode(percentage, forKey: .value)
        case .componentBuildDiscount(let percentage):
            try container.encode("componentBuildDiscount", forKey: .effectType)
            try container.encode(percentage, forKey: .value)
        case .tagEffectDoubler(let tag):
            try container.encode("tagEffectDoubler", forKey: .effectType)
            try container.encode(tag, forKey: .value)
        case .extraBuildPointsFlat(let amount):
            try container.encode("extraBuildPointsFlat", forKey: .effectType)
            try container.encode(amount, forKey: .value)
        case .extraComponentBuildPointsFlat(let amount):
            try container.encode("extraComponentBuildPointsFlat", forKey: .effectType)
            try container.encode(amount, forKey: .value)
        case .extraActionPointsFlat(let amount):
            try container.encode("extraActionPointsFlat", forKey: .effectType)
            try container.encode(amount, forKey: .value)
        case .extraImprovementSlots(let amount):
            try container.encode("extraImprovementSlots", forKey: .effectType)
            try container.encode(amount, forKey: .value)
        case .extraSpeciliazationSlots(let amount):
            try container.encode("extraSpeciliazationSlots", forKey: .effectType)
            try container.encode(amount, forKey: .value)
        case .extraMaxActionPoints(let amount):
            try container.encode("extraMaxActionPoints", forKey: .effectType)
            try container.encode(amount, forKey: .value)
        }
    }
    
    public func applyEffectToPlayer(_ player: Player) -> Player {
        switch self {
        case .extraIncomeFlat(let amount):
            return player.extraIncome(amount: amount)
        case .extraTechFlat(let amount):
            return player.extraTech(amount: amount)
        case .interestOnCash(let percentage):
            return player.extraIncome(amount: player.cash * (percentage / 100.0))
        case .extraIncomeDailyIncome(let times):
            return player.extraIncome(amount: player.cashPerTick * times)
        case .oneShot(let shortName):
            return (try? player.removeImprovement(shortName)) ?? player
        case .tagEffectDoubler(let tag):
            let improvements = player.completedImprovements.filter {$0.tags.contains(tag)}
            var changedPlayer = player
            for improvement in improvements {
                changedPlayer = improvement.applyEffectForOwner(player: changedPlayer)
            }
            return changedPlayer
        case .extraBuildPointsFlat(let amount):
            return player.extraBuildPoints(amount: amount)
        case .extraComponentBuildPointsFlat(let amount):
            return player.extraComponentBuildPoints(amount: amount)
        case .extraActionPointsFlat(let amount):
            return player.extraActionPoints(amount: amount)
        default:
            return player
        }
    }
    
    public var description: String {
        switch self {
        case .extraIncomeFlat(let amount):
            return "+$\(cashFormatter(amount)) per day"
        case .extraTechFlat(let amount):
            return "+\(amount) technology points per day"
        case .interestOnCash(let percentage):
            return "+\(percentage)% on your total cash per day"
        case .tagEffectDoubler(let tag):
            return "Receive double benefits from all improvements with tag '\(tag)'"
        case .extraBuildPointsFlat(let amount):
            return "Build improvements \(amount * 100.0)% faster"
        case .extraComponentBuildPointsFlat(let amount):
            return "Build components \(amount * 100.0)% faster"
        case .extraActionPointsFlat(let amount):
            return "+\(amount) Actions Points per day"
        case .extraImprovementSlots(let amount):
            return "+\(amount) extra improvement slot\(amount > 1 ? "s" : "")."
        case .extraSpeciliazationSlots(let amount):
            return "+\(amount) extra specilization slot\(amount > 1 ? "s" : "")."
        case .extraMaxActionPoints(let amount):
            return "+\(amount) to maximum action point\(amount > 1 ? "s" : "")."
        case .extraIncomeDailyIncome(let times):
            return "+\(times)x your daily cash income."
        case .oneShot(_):
            return "One shot, removed after use."
        default:
            return "Effect \(self). Add a description for a more descriptive message."
        }
    }
}

/// we use this protocol to be able to call `thingy.effectDescription` to get a string with all updateEffects.
protocol Effector {
    var updateEffects: [Effect] { get }
}

extension Effector {
    public var effectDescription: String {
        let effectStrings = updateEffects.map { effect in
            effect.description
        }
        
        return effectStrings.joined(separator: "\n")
    }
}

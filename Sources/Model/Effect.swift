//
//  Effect.swift
//  App
//
//  Created by Maarten Engels on 11/01/2020.
//

import Foundation

public enum Effect: Codable {
    enum EffectError: Error {
        case decodingUnknownEffectType
    }
    
    enum EffectCodingKeys: CodingKey {
        case effectType
        case value
    }
    
    case extraIncomeFlat(amount: Double)
    case extraTechFlat(amount: Double)
    case extraIncomePercentage(percentage: Double)
    //case extraTechPercentage(percentage: Double)
    case lowerProductionTimePercentage(percentage: Double)
    case extraIncomeDailyIncome(times: Double)
    case oneShot(shortName: Improvement.ShortName)
    case shortenComponentBuildTime(percentage: Double)
    case componentBuildDiscount(percentage: Double)
    
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
            self = .extraIncomePercentage(percentage: percentage)
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
        case .extraIncomePercentage(let percentage):
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
        }
    }
    
    public func applyEffectToPlayer(_ player: Player) -> Player {
        switch self {
        case .extraIncomeFlat(let amount):
            return player.extraIncome(amount: amount)
        case .extraTechFlat(let amount):
            return player.extraTech(amount: amount)
        case .extraIncomePercentage(let percentage):
            return player.extraIncome(amount: player.cash * (percentage / 100.0))
        case .extraIncomeDailyIncome(let times):
            return player.extraIncome(amount: player.cashPerTick * times)
        case .oneShot(let shortName):
            return player.removeImprovement(shortName)
        default:
            return player
        }
    }
}

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
        case TechConsultancy = 0
        case Faculty = 1
        case SpaceTourism = 2
        case DroneDeliveryService = 3
        case CrowdFundingCampaign = 4
        case InvestmentPortfolio_S = 5
        case ResearchGrant = 6
        case BioResearchFacility = 7
        case AIAssistedResearchPlant = 8
        case GrapheneSolarCellsPlant = 9
        case SolarAirLine = 10
        case BatteryOutlet = 11
    }
    
    public static let allImprovements = [
        Improvement(shortName: .TechConsultancy, name: "Technology Consultancy firm", description: "This firm is the bread and butter of your company. It keeps you 'in the black' while you pertake in the mission and pursue other endeavors.\nCreates both extra technologypoints (+7), as well as a little extra income (+7500). You start with this.", cost: 1_000_000, buildTime: 365 / 6, requiredTechnologyShortnames: []),
        Improvement(shortName: .Faculty, name: "Faculty of Applied Sciences", description: "Buy yourself a faculty on a prestigious University and assure yourself of a steady supply of extra technology points (+5)", cost: 250_000, buildTime: 365 / 12, requiredTechnologyShortnames: []),
        Improvement(shortName: .BatteryOutlet, name: "Batteries'r'Us", description: "Create an outlet selling your new battery tech in all units of all shapes and sizes. And make a little profit (+5k) as you go.", cost: 500_000, buildTime: 365 / 12, requiredTechnologyShortnames: [.LiIonBattery_HY]),
        Improvement(shortName: .SpaceTourism, name: "Space Tourism Agency", description: "Allow the rich the opportunity to look at Earth from Space! As you are piggy backing on your existing technology, this is a very cost effective way of generating some extra income (+7500)", cost: 1_000_000, buildTime: 365 / 12, requiredTechnologyShortnames: [.FuelConservation_2]),
        Improvement(shortName: .DroneDeliveryService, name: "Drone Delivery Service", description: "There's a lot of money to be made if you can delivery parcels more effeciently. Just make sure the drones don't get lost on their way. Extra income: +10k", cost: 500_000, buildTime: 365 / 6, requiredTechnologyShortnames: [.RecoverableAI, .LiIonBattery_HY]),
        Improvement(shortName: .InvestmentPortfolio_S, name: "Small Investment Portfolio", description: "Setting aside a portion of your capital offers you the possibility of gaining interest over your entire cash position. The more you invest, the higher the expected return. For this small investment, you can expect a 4% ROI", cost: 1_000_000, buildTime: 1, requiredTechnologyShortnames: []),
        Improvement(shortName: .BioResearchFacility, name: "Bio Research Facility Grant", description: "Use your advancements in ML for bio research and generate extra tech points (+10)", cost: 1_000_000, buildTime: 365, requiredTechnologyShortnames: [.AdaptiveML]),
        Improvement(shortName: .AIAssistedResearchPlant, name: "Bio Research Facility Grant", description: "Use your advancements in AI for bio research and generate extra tech points (+10)", cost: 2_000_000, buildTime: 365, requiredTechnologyShortnames: [.RecoverableAI]),
        Improvement(shortName: .GrapheneSolarCellsPlant, name: "Graphene Solar Plant", description: "While the regular solar cells market is highly saturated and has very small margins, the new graphene based ones create a new market, with comparatively interesting margins (+20k).", cost: 5_000_000, buildTime: 365, requiredTechnologyShortnames: [.GrapheneSolarCells]),
        Improvement(shortName: .SolarAirLine, name: "Solar Airline", description: "The world first commercial airline powered completely using solar aircraft. This is guaranteerd to provide a great and steady income (+100k).", cost: 10_000_000, buildTime: 365*2, requiredTechnologyShortnames: [.GrapheneSolarCells, .GrapheneBatteries]),
        Improvement(shortName: .CrowdFundingCampaign, name: "Crowd Funding Campaign", description: "A reasonably fast way to get generate some extra income. When it completes, you receive 100x your current daily income.", cost: 20_000, buildTime: 365 / 12, requiredTechnologyShortnames: []),
        Improvement(shortName: .ResearchGrant, name: "Research Grant", description: "Investing a little money to sponsor research and development, provides you with some extra technology points (+75).", cost: 50_000, buildTime: 7, requiredTechnologyShortnames: []),
        
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
                return player
            }
        case .Faculty:
            return { player in return player.extraTech(amount: 5) }
        case .BioResearchFacility:
            return { player in return player.extraTech(amount: 10) }
        case .AIAssistedResearchPlant:
            return { player in return player.extraTech(amount: 10) }
        case .BatteryOutlet:
            return { player in return player.extraIncome(amount: 5000) }
        case .SpaceTourism:
            return { player in return player.extraIncome(amount: 7500) }
        case .DroneDeliveryService:
            return { player in return player.extraIncome(amount: 10_000) }
        case .GrapheneSolarCellsPlant:
            return { player in return player.extraIncome(amount: 10_000) }
        case .SolarAirLine:
            return { player in return player.extraIncome(amount: 100_000) }
        case .CrowdFundingCampaign:
            return { player in
                var changedPlayer = player.extraIncome(amount: player.cashPerTick * 100.0)
                changedPlayer = changedPlayer.removeImprovement(self)
                return changedPlayer
            }
        case .InvestmentPortfolio_S:
            return { player in
                return player.extraIncome(amount: player.cash * 0.04)
            }
        case .ResearchGrant:
            return { player in
                var changedPlayer = player.extraTech(amount: 75)
                changedPlayer = changedPlayer.removeImprovement(self)
                return changedPlayer
            }
        }
    }
    
    public let description: String
    public let cost: Double
    public let buildTime: Int // in days/ticks
    public private(set) var buildStartedOn: Date?
    public private(set) var percentageCompleted: Double = 0
    public let requiredTechnologyShortnames: [Technology.ShortName]
    public var requiredTechnologies: [Technology] {
        return requiredTechnologyShortnames.compactMap { shortName in
            return Technology.getTechnologyByName(shortName)
        }
    }
    
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
            //print("Improvement \(name) owned by player \(player.username) is not yet complete.")
            return player
        }
        
        return updateEffectForPlayer(player)
    }
    
    public func playerHasPrerequisitesForImprovement(_ player: Player) -> Bool {
        for prereq in requiredTechnologyShortnames {
            if player.unlockedTechnologyNames.contains(prereq) == false {
                return false
            }
        }
        
        // all prerequisites met.
        return true
    }
    
    public static func unlockedImprovementsForPlayer(_ player: Player) -> [Improvement] {
        return Improvement.allImprovements.filter { improvement in
            return improvement.playerHasPrerequisitesForImprovement(player)
        }
    }
    
    
}

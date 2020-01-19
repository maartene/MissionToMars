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
        case improvementCannotBeRushed
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
        case PrefabFurniture = 12
        case OrbitalShipyard = 13
    }
    
    public static let allImprovements = [
        // Generic improvements
        Improvement(shortName: .TechConsultancy, name: "Technology Consultancy firm", description: "This firm is the bread and butter of your company. It keeps you 'in the black' while you pertake in the mission and pursue other endeavors.\nCreates both extra technologypoints (+7), as well as a little extra income (+7500). You start with this.", cost: 1_000_000, buildTime: 365 / 6, updateEffects: [.extraIncomeFlat(amount: 7500), .extraTechFlat(amount: 7)]),
        Improvement(shortName: .Faculty, name: "Faculty of Applied Sciences", description: "Buy yourself a faculty on a prestigious University and assure yourself of a steady supply of extra technology points (+5)", cost: 250_000, buildTime: 365 / 12, updateEffects: [.extraTechFlat(amount: 5)]),
        
        // Economy improvements
        Improvement(shortName: .BatteryOutlet, name: "Batteries'r'Us", description: "Create an outlet selling your new battery tech in all units of all shapes and sizes. And make a little profit (+5k) as you go.", cost: 500_000, buildTime: 365 / 12, requiredTechnologyShortnames: [.LiIonBattery_HY], updateEffects: [.extraIncomeFlat(amount: 5000)]),
        Improvement(shortName: .SpaceTourism, name: "Space Tourism Agency", description: "Allow the rich the opportunity to look at Earth from Space! As you are piggy backing on your existing technology, this is a very cost effective way of generating some extra income (+7500)", cost: 1_000_000, buildTime: 365 / 12, requiredTechnologyShortnames: [.FuelConservation_2], updateEffects: [.extraIncomeFlat(amount: 7500)]),
        Improvement(shortName: .DroneDeliveryService, name: "Drone Delivery Service", description: "There's a lot of money to be made if you can delivery parcels more effeciently. Just make sure the drones don't get lost on their way. Extra income: +10k", cost: 500_000, buildTime: 365 / 6, requiredTechnologyShortnames: [.RecoverableAI, .LiIonBattery_HY], updateEffects: [.extraIncomeFlat(amount: 10_000)]),
        Improvement(shortName: .InvestmentPortfolio_S, name: "Small Investment Portfolio", description: "Setting aside a portion of your capital offers you the possibility of gaining interest over your entire cash position. The more you invest, the higher the expected return. For this small investment, you can expect a 1% ROI", cost: 1_000_000, buildTime: 1, rushable: false, updateEffects: [.extraIncomePercentage(percentage: 1.0)]),
        Improvement(shortName: .GrapheneSolarCellsPlant, name: "Graphene Solar Plant", description: "While the regular solar cells market is highly saturated and has very small margins, the new graphene based ones create a new market, with comparatively interesting margins (+20k).", cost: 5_000_000, buildTime: 365, requiredTechnologyShortnames: [.GrapheneSolarCells], updateEffects: [.extraIncomeFlat(amount: 20_000)]),
        Improvement(shortName: .SolarAirLine, name: "Solar Airline", description: "The world first commercial airline powered completely using solar aircraft. This is guaranteerd to provide a great and steady income (+100k).", cost: 10_000_000, buildTime: 365*2, requiredTechnologyShortnames: [.SolarFlight], updateEffects: [.extraIncomeFlat(amount: 100_000)]),
        Improvement(shortName: .PrefabFurniture, name: "Prefab Furniture Store", description: "A Swedish innovation! Furniture you can immediately pick-up, take home in flat boxes. Some assembly required. Extra income (+25k). Also lowers improvement building time by 20%.", cost: 1_000_000, buildTime: 365 / 4, rushable: false, updateEffects: [.extraIncomeFlat(amount: 25_000)], staticEffects: [.lowerProductionTimePercentage(percentage: 20.0)]),
        
        // Technology improvements
        Improvement(shortName: .BioResearchFacility, name: "Bio Research Facility", description: "Use your advancements in ML for bio research and generate extra tech points (+10)", cost: 1_000_000, buildTime: 365, requiredTechnologyShortnames: [.AdaptiveML], updateEffects: [.extraTechFlat(amount: 10)]),
        Improvement(shortName: .AIAssistedResearchPlant, name: "AI Assisted Research Plant", description: "Use your advancements in AI for research and generate extra tech points (+10)", cost: 2_000_000, buildTime: 365, requiredTechnologyShortnames: [.RecoverableAI], updateEffects: [.extraTechFlat(amount: 10)]),
        
        
        // Mission improvements
        Improvement(shortName: .OrbitalShipyard, name: "Orbital Shipyard", description: "Although very expensive to construct, it will make building components much easier. Component build time is reduced by 40% and components are 10% cheaper to build.", cost: 750_000_000, buildTime: 365, rushable: false, updateEffects: [], staticEffects: [.componentBuildDiscount(percentage: 10.0), .shortenComponentBuildTime(percentage: 40.0)]),
        
        
        // repeatable improvements - for testing purposes, keep these at the end of the array.
        Improvement(shortName: .CrowdFundingCampaign, name: "Crowd Funding Campaign", description: "A reasonably fast way to get generate some extra income, but it requires your full attention (you can't built any other improvements during the duration of the campaign). When it completes, you receive 100x your current daily income.", cost: 20_000, buildTime: 365 / 12, allowsParrallelBuild: false, rushable: false, updateEffects: [.extraIncomeDailyIncome(times: 100), .oneShot(shortName: .CrowdFundingCampaign)]),
        Improvement(shortName: .ResearchGrant, name: "Research Grant", description: "Investing a little money to sponsor research and development, provides you with some extra technology points (+75).", cost: 50_000, buildTime: 7, rushable: false, updateEffects: [.extraTechFlat(amount: 75), .oneShot(shortName: .ResearchGrant)]),
    ]
    
    public static func getImprovementByName(_ shortName: ShortName) -> Improvement? {
        return allImprovements.first(where: { i in i.shortName == shortName })
    }
    
    public static func == (lhs: Improvement, rhs: Improvement) -> Bool {
        return lhs.shortName == rhs.shortName
    }
    
    public let shortName: ShortName
    public let name: String
    public let description: String
    public let cost: Double
    public let buildTime: Int // in days/ticks
    public let requiredTechnologyShortnames: [Technology.ShortName]
    public let allowsParrallelBuild: Bool
    public let rushable: Bool
    public let updateEffects: [Effect]
    public let staticEffects: [Effect]
    
    /*init(shortName: ShortName, name: String, description: String, cost: Int, buildTime: Int, requiredTechnologyShortnames: [Technology.ShortName] = [], allowsParrallelBuild: Bool = true, rushable: Bool = true, updateEffects: [Effect] = [], staticEffects: [Effect] = []) {
        self = Improvement(shortName: shortName, name: name, description: description, cost: Double(cost), buildTime: buildTime, requiredTechnologyShortnames: requiredTechnologyShortnames, allowsParrallelBuild: allowsParrallelBuild, rushable: rushable, updateEffects: updateEffects, staticEffects: staticEffects)
    }*/
    
    init(shortName: ShortName, name: String, description: String, cost: Double, buildTime: Int, requiredTechnologyShortnames: [Technology.ShortName] = [], allowsParrallelBuild: Bool = true, rushable: Bool = true, updateEffects: [Effect] = [], staticEffects: [Effect] = []) {
        self.shortName = shortName
        self.name = name
        self.description = description
        self.cost = cost
        self.buildTime = buildTime
        self.requiredTechnologyShortnames = requiredTechnologyShortnames
        self.allowsParrallelBuild = allowsParrallelBuild
        self.rushable = rushable
        self.updateEffects = updateEffects
        self.staticEffects = staticEffects
    }
    
    public private(set) var buildStartedOn: Date?
    public private(set) var percentageCompleted: Double = 0
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
    
    public func updateImprovement(ticks: Int = 1, buildTimeFactor: Double = 1.0) -> Improvement {
        var changedImprovement = self
        
        if buildStartedOn != nil {
            let netBuildTime = Double(buildTime) * buildTimeFactor
            let progress = Double(ticks) / netBuildTime
            changedImprovement.percentageCompleted += 100.0 * progress
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
        
        var affectedPlayer = player
        
        for effect in updateEffects {
            affectedPlayer = effect.applyEffectToPlayer(affectedPlayer)
        }
        
        return affectedPlayer
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
    
    public func rush() throws -> Improvement {
        guard rushable else {
            throw ImprovementError.improvementCannotBeRushed
        }
        
        var rushedImprovement = self
        rushedImprovement.percentageCompleted = 100
        return rushedImprovement
    }
    
}

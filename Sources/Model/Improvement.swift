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
        //case InvestmentPortfolio_S = 5
        case BuyPatentPortfolio = 6
        case BioResearchFacility = 7
        case AIAssistedResearchPlant = 8
        case GrapheneSolarCellsPlant = 9
        case SolarAirLine = 10
        case BatteryOutlet = 11
        case PrefabFurniture = 12
        case OrbitalShipyard = 13
        case InvestmentBank = 14
    }
    
    public static let allImprovements = [
        // Start improvements
        Improvement(shortName: .TechConsultancy, name: "Technology Consultancy firm", description: "This firm provides a great versetile start if you don't want to commit to money making or researching new technologies. Good fit if you want to go solo, but in the long run specializing might be more attractive.\nCreates both extra technologypoints (+2), as well as a little extra income (+6500).", cost: 0, buildTime: 365 / 6, updateEffects: [.extraIncomeFlat(amount: 6500), .extraTechFlat(amount: 2)]),
        Improvement(shortName: .Faculty, name: "Faculty of Applied Sciences", description: "You start with a faculty on a prestigious University and assure yourself of a steady supply of extra technology points (+15) and a little income (+1k).", cost: 0, buildTime: 365 / 12, updateEffects: [.extraTechFlat(amount: 15), .extraIncomeFlat(amount: 1000)]),
        Improvement(shortName: .InvestmentBank, name: "Investment Bank", description: "If you want to make it rain (become very VERY rich), starting an investment bank is a great start. The bank provides extra income (+15k) as well as ROI on your outstanding balance (+1% per day). However, it doesn't generate any technology. You will need to find other ways if you want to advance the tech tree.", cost: 0, buildTime: 365 / 12, updateEffects: [.extraIncomeFlat(amount: 15_000), .extraIncomePercentage(percentage: 1.0)]),
        
        // Economy improvements
        Improvement(shortName: .BatteryOutlet, name: "Batteries'r'Us", description: "Create an outlet selling your new battery tech in all units of all shapes and sizes. And make a little profit (+5k) as you go.", cost: 500_000, buildTime: 365 / 12, requiredTechnologyShortnames: [.LiIonBattery_HY], updateEffects: [.extraIncomeFlat(amount: 5000)]),
        Improvement(shortName: .SpaceTourism, name: "Space Tourism Agency", description: "Allow the rich the opportunity to look at Earth from Space! As you are piggy backing on your existing technology, this is a very cost effective way of generating some extra income (+7500)", cost: 1_000_000, buildTime: 365 / 12, requiredTechnologyShortnames: [.FuelConservation_2], updateEffects: [.extraIncomeFlat(amount: 7500)]),
        Improvement(shortName: .DroneDeliveryService, name: "Drone Delivery Service", description: "There's a lot of money to be made if you can delivery parcels more effeciently. Just make sure the drones don't get lost on their way. Extra income: +10k", cost: 500_000, buildTime: 365 / 6, requiredTechnologyShortnames: [.RecoverableAI, .LiIonBattery_HY], updateEffects: [.extraIncomeFlat(amount: 10_000)]),
        Improvement(shortName: .GrapheneSolarCellsPlant, name: "Graphene Solar Plant", description: "While the regular solar cells market is highly saturated and has very small margins, the new graphene based ones create a new market, with comparatively interesting margins (+20k).", cost: 5_000_000, buildTime: 365, requiredTechnologyShortnames: [.GrapheneSolarCells], updateEffects: [.extraIncomeFlat(amount: 20_000)]),
        Improvement(shortName: .SolarAirLine, name: "Solar Airline", description: "The world first commercial airline powered completely using solar aircraft. This is guaranteerd to provide a great and steady income (+100k).", cost: 10_000_000, buildTime: 365*2, requiredTechnologyShortnames: [.SolarFlight], updateEffects: [.extraIncomeFlat(amount: 100_000)]),
        Improvement(shortName: .PrefabFurniture, name: "Prefab Furniture Store", description: "A Swedish innovation! Furniture you can immediately pick-up, take home in flat boxes. Some assembly required. Extra income (+25k). Also lowers improvement building time by 20%.", cost: 1_000_000, buildTime: 365 / 4, rushable: false, updateEffects: [.extraIncomeFlat(amount: 25_000)], staticEffects: [.lowerProductionTimePercentage(percentage: 20.0)]),
        
        // Technology improvements
        Improvement(shortName: .BioResearchFacility, name: "Bio Research Facility", description: "Use your advancements in ML for bio research and generate extra tech points (+10)", cost: 1_000_000, buildTime: 365, requiredTechnologyShortnames: [.AdaptiveML], updateEffects: [.extraTechFlat(amount: 10)]),
        Improvement(shortName: .AIAssistedResearchPlant, name: "AI Assisted Research Plant", description: "Use your advancements in AI for research and generate extra tech points (+10)", cost: 2_000_000, buildTime: 365, requiredTechnologyShortnames: [.RecoverableAI], updateEffects: [.extraTechFlat(amount: 10)]),
        
        
        // Mission improvements
        Improvement(shortName: .OrbitalShipyard, name: "Orbital Shipyard", description: "Although very expensive to construct, it will make building components much easier. Component build time is reduced by 40% and components are 10% cheaper to build.", cost: 750_000_000, buildTime: 365, rushable: false, updateEffects: [], staticEffects: [.componentBuildDiscount(percentage: 10.0), .shortenComponentBuildTime(percentage: 40.0)]),
        
        
        // repeatable improvements - for testing purposes, keep these at the end of the array.
        // you should only be able to do this once per stage
        Improvement(shortName: .CrowdFundingCampaign, name: "Crowd Funding Campaign", description: "A reasonably fast way to get generate some extra income, but it requires your full attention (you can't built any other improvements during the duration of the campaign). When it completes, you receive 100x your current daily income.", cost: 20_000, buildTime: 365 / 12, allowsParrallelBuild: false, rushable: false, updateEffects: [.extraIncomeDailyIncome(times: 100), .oneShot(shortName: .CrowdFundingCampaign)]),
        Improvement(shortName: .BuyPatentPortfolio, name: "Buy Patent Portfolio", description: "A quick, but expensive way to get some extra research points (+\(Int(150000.0 / CASH_TO_TECH_CONVERSION_RATE))).", cost: 150_000, buildTime: 7, allowsParrallelBuild: false, rushable: false, updateEffects: [.extraTechFlat(amount: 150000.0 / CASH_TO_TECH_CONVERSION_RATE), .oneShot(shortName: .BuyPatentPortfolio)]),
    ]
    
    public static var buildableImprovements: [Improvement] {
        return allImprovements.filter { $0.cost > 0 }
    }
    
    public static var startImprovements: [Improvement] {
        return allImprovements.filter { $0.cost == 0 }
    }
    
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
        return Improvement.buildableImprovements.filter { improvement in
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

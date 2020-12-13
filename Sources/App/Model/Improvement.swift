//
//  Improvement.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation
//import Vapor

public enum Tag: String, Codable {
    case Finance
    case AI
    case Construction
    case Biotech
    case SpaceTravel = "Space Travel"
    case Retail
    case Specialization
    case Unique
}

public enum BuildImprovementOption: Int, Codable {
    case ignoreUniqueness
    case ignoreSpecializationSlotCount
    case ignoreTechPrereqs
}

public struct Improvement: Codable, Equatable, Effector {
    public enum ImprovementError: Error {
        case componentAlreadyBeingBuilt
        case improvementCannotBeRushed
        case improvementIncomplete
        case improvementCannotBeTriggered
        case improvementIsUnique
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
        case AdvertisingCampaign = 15
        case AI_TAG = 16
        case Construction_TAG = 17
        case BioTech_TAG = 18		
        case SpaceTravel_TAG = 19
        case Retail_TAG = 20
        //case TuningShop = 21
        //case DesignStudio = 22
        //case SecondBranch = 23
    }
    
    public static let allImprovements = [
        // Start improvements
        Improvement(shortName: .TechConsultancy, name: "Technology Consultancy firm", description: "This firm provides a great versetile start if you don't want to commit to money making or researching new technologies. Good fit if you want to go solo, but in the long run specializing might be more attractive.", cost: 0, buildTime: 365 / 6, updateEffects: [.extraIncomeFlat(amount: 6500), .extraTechFlat(amount: 2)], tags: [.AI, .SpaceTravel]),
        Improvement(shortName: .Faculty, name: "Faculty of Applied Sciences", description: "You start with a faculty on a prestigious University and assure yourself of a steady supply of extra technology points and a little income.", cost: 0, buildTime: 365 / 12, updateEffects: [.extraTechFlat(amount: 15), .extraIncomeFlat(amount: 1000)], tags: [.Biotech, .AI, .SpaceTravel]),
        Improvement(shortName: .InvestmentBank, name: "Investment Bank", description: "If you want to make it rain (become very VERY rich), starting an investment bank is a great start. The bank provides extra income as well as ROI on your outstanding balance. However, it doesn't generate any technology. You will need to find other ways if you want to advance the tech tree.", cost: 0, buildTime: 365 / 12, updateEffects: [.extraIncomeFlat(amount: 15_000), .interestOnCash(percentage: 0.5)], tags: [.Finance]),
        
        // Economy improvements
        Improvement(shortName: .BatteryOutlet, name: "Batteries'r'Us", description: "Create an outlet selling your new battery tech in all units of all shapes and sizes. And make a little profit as you go.", cost: 500_000, buildTime: 365 / 12, requiredTechnologyShortnames: [.LiIonBattery_HY], updateEffects: [.extraIncomeFlat(amount: 5000)],tags: [.Retail]),
        Improvement(shortName: .DroneDeliveryService, name: "Drone Delivery Service", description: "There's a lot of money to be made if you can delivery parcels more effeciently. Just make sure the drones don't get lost on their way.", cost: 1_000_000, buildTime: 365 / 6, requiredTechnologyShortnames: [.RecoverableAI, .LiIonBattery_HY], updateEffects: [.extraIncomeFlat(amount: 10_000)], tags: [.Retail, .AI]),
        Improvement(shortName: .GrapheneSolarCellsPlant, name: "Graphene Solar Plant", description: "While the regular solar cells market is highly saturated and has very small margins, the new graphene based ones create a new market, with comparatively interesting margins.", cost: 5_000_000, buildTime: 365 / 2, requiredTechnologyShortnames: [.GrapheneSolarCells], updateEffects: [.extraIncomeFlat(amount: 50_000)], tags: [.Construction]),
        Improvement(shortName: .SolarAirLine, name: "Solar Airline", description: "The world first commercial airline powered completely using solar aircraft. This is guaranteerd to provide a great and steady income.", cost: 10_000_000, buildTime: 365*2, requiredTechnologyShortnames: [.SolarFlight], updateEffects: [.extraIncomeFlat(amount: 100_000)], tags: []),
        Improvement(shortName: .SpaceTourism, name: "Space Tourism Agency", description: "Allow the rich the opportunity to look at Earth from Space! As you are piggy backing on your existing technology, this is a very cost effective way of generating some extra income.", cost: 100_000_000, buildTime: 365 / 12, requiredTechnologyShortnames: [.FuelConservation_2], updateEffects: [.extraIncomeFlat(amount: 1_000_000)], tags: [.SpaceTravel]),
        Improvement(shortName: .PrefabFurniture, name: "Prefab Furniture Store", description: "A Swedish innovation! Furniture you can immediately pick-up, take home in flat boxes. Some assembly required. Extra income and also lowers improvement building time.", cost: 1_000_000, buildTime: 365 / 4, requiredTechnologyShortnames: [.PackageOptimization], rushable: false,  updateEffects: [.extraIncomeFlat(amount: 5_000), .extraBuildPointsFlat(amount: 0.2)], tags: [.Retail, .Construction]),
        
        // Technology improvements
        /*Improvement(shortName: .TuningShop, name: "Tuning Shop (STUB)", description: "Use your advances in fuel conservation to increase the efficiency of all types of engines. (STUB: required to give something to build regardsless of the tech choice you make.", cost: 1_000_000, buildTime: 365 / 4, requiredTechnologyShortnames: [.FuelConservation_1], updateEffects: [.extraIncomeFlat(amount: 5_000), .extraTechFlat(amount: 1)]),*/
        Improvement(shortName: .BioResearchFacility, name: "Bio Research Facility", description: "Use your advancements in ML for bio research and generate extra tech points.", cost: 1_000_000, buildTime: 365 / 4, requiredTechnologyShortnames: [.AdaptiveML], updateEffects: [.extraTechFlat(amount: 10)], tags: [.AI, .Biotech]),
        Improvement(shortName: .AIAssistedResearchPlant, name: "AI Assisted Research Plant", description: "Use your advancements in AI for research and generate extra tech points.", cost: 2_000_000, buildTime: 365, requiredTechnologyShortnames: [.RecoverableAI], updateEffects: [.extraTechFlat(amount: 10)], tags: [.AI, .SpaceTravel]),
        
        // Generic improvements
        //Improvement(shortName: .DesignStudio, name: "Design Studio (STUB)", description: "(STUB: required to give something to build if you not yet selected a tech.) Not very efficient - unlock technologies to unlock better improvements.", cost: 500_000, buildTime: 365 / 6, updateEffects: [.extraIncomeFlat(amount: 1_000), .extraTechFlat(amount: 1)]),
        //Improvement(shortName: .SecondBranch, name: "Second Branch", description: "A second branch for your company brings additional Action Points.", cost: 500_000, buildTime: 365 / 3, requiredTechnologyShortnames: [.AgileLeadership], rushable: false, triggerable: false, updateEffects: [.extraActionPointsFlat(amount: 1)], tags: [.Finance]),
        
        // Mission improvements
        Improvement(shortName: .OrbitalShipyard, name: "Orbital Shipyard", description: "Although very expensive to construct, it will make building components much easier. Component build time is reduced.", cost: 750_000_000, buildTime: 365, requiredTechnologyShortnames: [.FuelConservation_2, .PackageOptimization], rushable: false, triggerable: false, updateEffects: [.extraComponentBuildPointsFlat(amount: 0.4)], tags: [.Construction, .SpaceTravel]),
        
        // Tag based improvements
        Improvement(shortName: .AI_TAG, name: "AI specilization", description: "Your focus on AI related improvements makes these improvements twice as effective.", cost: 100_000, buildTime: 7, requiredTechnologyShortnames: [.RecoverableAI], triggerable: false, updateEffects: [.tagEffectDoubler(tag: .AI)], tags: [.Specialization, .Unique]),
        Improvement(shortName: .BioTech_TAG, name: "BioTech specilization", description: "Your focus on BioTech related improvements makes these improvements twice as effective.", cost: 100_000, buildTime: 7, requiredTechnologyShortnames: [.AdaptiveML], triggerable: false, updateEffects: [.tagEffectDoubler(tag: .Biotech)], tags: [.Specialization, .Unique]),
        Improvement(shortName: .Construction_TAG , name: "Construction specilization", description: "Your focus on Construction related improvements makes these improvements twice as effective.", cost: 100_000, buildTime: 7, requiredTechnologyShortnames: [.PackageOptimization], triggerable: false, updateEffects: [.tagEffectDoubler(tag: .Construction)], tags: [.Specialization, .Unique]),
        Improvement(shortName: .Retail_TAG, name: "Retail specilization", description: "Your focus on Retail related improvements makes these improvements twice as effective.", cost: 100_000, buildTime: 7, requiredTechnologyShortnames: [.LiIonBattery_HY], triggerable: false, updateEffects: [.tagEffectDoubler(tag: .Retail)], tags: [.Specialization, .Unique]),
        Improvement(shortName: .SpaceTravel_TAG, name: "Space Travel specilization", description: "Your focus on Space Travel related improvements makes these improvements twice as effective.", cost: 100_000, buildTime: 7, requiredTechnologyShortnames: [.FuelConservation_2], triggerable: false, updateEffects: [.tagEffectDoubler(tag: .SpaceTravel)], tags: [.Specialization, .Unique]),
        
        
        // repeatable improvements - for testing purposes, keep these at the end of the array.
        // you should only be able to do this once per stage
        Improvement(shortName: .CrowdFundingCampaign, name: "Crowd Funding Campaign", description: "A reasonably fast way to get generate some extra income, but it requires your full attention (you can't built any other improvements during the duration of the campaign). When it completes, you receive 10x your current daily income.", cost: 20_000, buildTime: 365 / 12, rushable: false, triggerable: false, updateEffects: [.extraIncomeDailyIncome(times: 10), .oneShot(shortName: .CrowdFundingCampaign)]),
        Improvement(shortName: .AdvertisingCampaign, name: "Advertising Campaign", description: "Tripples income for the next 30 days. (you get your cash after 30 days)", cost: 2_000_000, buildTime: 30, rushable: false, triggerable: false, updateEffects: [.extraIncomeDailyIncome(times: 60), .oneShot(shortName: .AdvertisingCampaign)]),
        Improvement(shortName: .BuyPatentPortfolio, name: "Buy Patent Portfolio", description: "A quick, but expensive way to get some extra research points (+\(Int(150000.0 / CASH_TO_TECH_CONVERSION_RATE))).", cost: 150_000, buildTime: 7, rushable: false, triggerable: false, updateEffects: [.extraTechFlat(amount: 150000.0 / CASH_TO_TECH_CONVERSION_RATE), .oneShot(shortName: .BuyPatentPortfolio)]),
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
    public let rushable: Bool
    public let triggerable: Bool
    public let updateEffects: [Effect]
    public let tags: [Tag]
    
    init(shortName: ShortName, name: String, description: String, cost: Double, buildTime: Int, requiredTechnologyShortnames: [Technology.ShortName] = [], rushable: Bool = true, triggerable: Bool = true, updateEffects: [Effect] = [], tags: [Tag] = []) {
        self.shortName = shortName
        self.name = name
        self.description = description
        self.cost = cost
        self.buildTime = buildTime
        self.requiredTechnologyShortnames = requiredTechnologyShortnames
        self.rushable = rushable
        self.triggerable = triggerable
        self.updateEffects = updateEffects
        self.tags = tags
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
    
    public func updateImprovement(buildPoints: Double) -> (updatedImprovement: Improvement, remainingBuildPoints: Double) {
        var changedImprovement = self
        var updatedBuildPoints = buildPoints
        
        if buildStartedOn != nil && changedImprovement.percentageCompleted < 100.0 {
            let progress = buildPoints / Double(buildTime)
            changedImprovement.percentageCompleted += 100.0 * progress
            updatedBuildPoints = 0
        }
        
        if changedImprovement.percentageCompleted > 100.0 {
            changedImprovement.percentageCompleted = 100.0
        }
        
        return (changedImprovement, updatedBuildPoints)
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
    
    
    public var hasOneShotEffect: Bool {
        for effect in updateEffects {
            switch effect {
            case .oneShot(_):
                return true
            default:
                break;
            }
        }
        return false
    }
}

//
//  Technology.swift
//  App
//
//  Created by Maarten Engels on 30/12/2019.
//

import Foundation

// Technology effects are instantanious (once you have enough technology points to buy them)
public struct Technology: Equatable, Codable, Effector {
    
    public enum ShortName: Int, Codable {
        case RecoverableAI = 0
        case FuelConservation_1 = 1
        case FuelConservation_2 = 2
        case AdaptiveML = 3
        case LiIonBattery = 4
        case LiIonBattery_HY = 5
        case GrapheneMaterials = 6
        case GrapheneSolarCells = 7
        case GrapheneBatteries = 8
        case SolarFlight = 9
        case RenewableRocketFuel = 10
        case FuelExtraction = 11
        case PackageOptimization = 12
        //case AdvancedRocketry
        case RadiationShielding = 13
        case AutonomousDriving = 14
        case AgileLeadership = 15
        case AdvancedSignalModulation = 16
        case ScaledAgileLeadership = 17
    }
    
    public static let allTechnologies = [
        //Technology(shortName: .AdvancedRocketry, name: "Advanced Rocketry", description: "Lorem Ipsum", cost: 50, prerequisites: [.RecoverableAI]),
        Technology(shortName: .RadiationShielding, name: "Cosmic Radiationg Shielding", description: "Lorem ipsum", cost: 600, updateEffects: [], prerequisites: [.GrapheneMaterials]),
        Technology(shortName: .FuelConservation_1, name: "Fuel Conservation 1", description: "Launching rockets to space is still very costly both in terms of the cost of fuel as the environmental impact. Improvements in fuel efficiency will undoubtedly pay themselves back many fold.", cost: 50, updateEffects: [], prerequisites: []),
        Technology(shortName: .RecoverableAI, name: "Recoverable AI", description: "The most difficult aspect of Artificial Intelligence is for an AI to respond to unexpected circumstances. Due to advances in Machine Learning, AI are now able to (eventually) get out of situation where they would remain stuck in the past. This makes application of AI possible in all sorts of new markets.", cost: 150, updateEffects: [], prerequisites: [.AdaptiveML]),
        Technology(shortName: .FuelConservation_2, name: "Fuel Conservation 2", description: "Further improvements in fuel efficiency are required to asprire to make the trip to Mars and back.", cost: 150, updateEffects: [], prerequisites: [.FuelConservation_1]),
        Technology(shortName: .AutonomousDriving, name: "Autonomous Driving (terristrial)", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.", cost: 300, updateEffects: [], prerequisites: [.RecoverableAI]),
        Technology(shortName: .AdaptiveML, name: "Adaptive Machine Learning", description: "The benefits of Machine Learning well known and understood. The next step is Machine Learning that can adapt to changing circumstances and detect internal bias. This technology has many medical applications.", cost: 50, updateEffects: [], prerequisites: []),
        Technology(shortName: .LiIonBattery, name: "Litium-Ion Battery", description: "Mature battery technology based on the well known LiIon technology. You start with this technology.", cost: 50, updateEffects: [], prerequisites: []),
        Technology(shortName: .LiIonBattery_HY, name: "High-yield LiIon Battery", description: "There is still more efficiency to get out of LiIon batteries. More efficiency leads to a higher energy density meaning either smaller batteries or longer battery life.", cost: 150, updateEffects: [], prerequisites: [.LiIonBattery]),
        Technology(shortName: .GrapheneMaterials, name: "Graphene Materials", description: "Graphine is a very promising material for all sorts of (photo) electric circuits. Costs remained prohibitive for a long time, but new processes finally make creating on graphene based materials feasible.", cost: 400, updateEffects: [], prerequisites: [.LiIonBattery_HY]),
        Technology(shortName: .GrapheneSolarCells, name: "Graphene Solar Cells", description: "Graphene based solar cells provide a lot more output per m2 than their silicon based brethren. Undoubtly this ushers in a new golden age of solar installation opportunities.", cost: 600, updateEffects: [], prerequisites: [.GrapheneMaterials]),
        Technology(shortName: .GrapheneBatteries, name: "Graphene Batteries", description: "The first major improvement to battery technology after LiIon.", cost: 800, updateEffects: [], prerequisites: [.GrapheneMaterials]),
        Technology(shortName: .SolarFlight, name: "Solar Energy Flight", description: "The development of graphene based solar panels and batteries finally made commercial solar flight possible, decreasing the cost and energy footprint of flight dramatically. Will you create the first commercial solar airline?", cost: 800, updateEffects: [], prerequisites: [.GrapheneBatteries, .GrapheneSolarCells]),
        Technology(shortName: .RenewableRocketFuel, name: "Renewable Rocket Fuel", description: "Renewable rocket fuel alleviates many of the disadvantages of rocket fuel and makes sending your first rocket to Mars a possibility.", cost: 150, updateEffects: [], prerequisites: [.FuelConservation_2]),
        Technology(shortName: .FuelExtraction, name: "Fuel Extraction", description: "The Mars soil and atmosphere contain substances that when correctly extracted and processed can be used as rocket fuel. To create a self sustaining colony and Mars economy, creating fuel locally is of paramount importance.", cost: 300, updateEffects: [], prerequisites: [.RenewableRocketFuel]),
        Technology(shortName: .PackageOptimization, name: "Optimized Packing", description: "Packing might sound simple, but packing with as high as possible densite while keeping packages small, standard size and manageble in weight in a very complex puzzle to solve.", cost: 200, updateEffects: [.extraImprovementSlots(amount: 1)], prerequisites: []),
        Technology(shortName: .AgileLeadership, name: "Agile Leadership", description: "Changing the leadership culture of your company offers makes it more efficient in the long run.", cost: 300, updateEffects: [], prerequisites: []),
        Technology(shortName: .AdvancedSignalModulation, name: "Advanced Signal Modulation", description: "Better signal modulation techniques increase bandwidth over extremely large distances.", cost: 300, updateEffects: [], prerequisites: [.RecoverableAI]),
        Technology(shortName: .ScaledAgileLeadership, name: "Scaled Agile Leadership", description: "Scaling your agile practives to enterprise level increases the maximum output your enterprises can create.", cost: 600, updateEffects: [.extraMaxActionPoints(amount: TECH_EXTRA_MAXIMUM_PLAYER_ACTION_POINTS)], prerequisites: [.AgileLeadership]),
    ]
    
    public static func getTechnologyByName(_ shortName: ShortName) -> Technology? {
        return allTechnologies.first(where: { technology in technology.shortName == shortName })
    }
    
    public static func == (lhs: Technology, rhs: Technology) -> Bool {
        return lhs.shortName == rhs.shortName
    }
    
    public let shortName: ShortName
    public let name: String
    public let description: String
    public let cost: Double                           // in tech points
    public let updateEffects: [Effect]
    public let prerequisites: [ShortName]
    
    public func playerHasPrerequisitesForTechnology(_ player: Player) -> Bool {
        for prereq in prerequisites {
            if player.unlockedTechnologyNames.contains(prereq) == false {
                return false
            }
        }
        
        // all prerequisites met.
        return true
    }
    
    public static func unlockableTechnologiesForPlayer(_ player: Player) -> [Technology] {
        return allTechnologies.filter { technology in
            return player.unlockedTechnologyNames.contains(technology.shortName) == false &&
            technology.playerHasPrerequisitesForTechnology(player)
        }
    }
}

//
//  Component.swift
//  App
//
//  Created by Maarten Engels on 22/12/2019.
//

import Foundation

public struct Component: Equatable, Codable {
    
    public enum ShortName: String, CaseIterable, Codable {
        case Rocket_S
        case Rocket_M
        case Rocket_L_1
        case Rocket_L_2
        case Rocket_L_3
        case Rocket_M_v2
        case MissionControl
        case Satellite
        case CommHub
        case Lander
        case Moxie
        case WaterExtractor
        case SolarPanel
        case Warehouse
        case Car
        case Supplies
        case Habitat
        case CrewQuarters_MO
        case CrewQuarters
        case Crew
    }
    
    public enum ComponentError: Error {
        case unknownShortName
        case componentAlreadyBeingBuilt
    }
    
    public static let allComponents: [Component] = [
        Component(shortName: .Rocket_S, name: "Small reusable rocket", description: "Although it is technically possible to reach Mars without reusable rockets, considering the large number of flights required the cost would be prohibitive. Although this first reusable rocket will be more expensive than a single use rocket, the subsequent ones will be much MUCH cheaper.", cost: 2_000_000_000, buildTime: 365, requiredTechnologyShortnames: [.AdvancedRocketry]),
        Component(shortName: .MissionControl, name: "Mission Control", description: "All your missions will be guided from here. You only need to build one once, these are the initial costs. It will be upgraded as per technological advancements. It will also receive upgrades when building subsequent components.", cost: 1_000_000_000, buildTime: 365 / 2, requiredTechnologyShortnames: []),
        Component(shortName: .Satellite, name: "Mars Orbital Satellite", description: "This sattelite has three major purposes: \n1) Provide imagery of Mars surface to help find suitable spot for colony \n2) Provide local communation \n3) Provide a beach head for communication with surface deployments", cost: 1_000_000_000, buildTime: 3 * 365 / 4, requiredTechnologyShortnames: [] ),
        Component(shortName: .Rocket_M, name: "Medium reusable rocket", description: "This reusable rocket is very similar to its shorter variant and grealy benefits from the research that went into its predecessor. It's main purpose is to ferry larger cargo. Note: the build time includes the flight time to Mars.", cost: 1_000_000_000, buildTime: 365 * 3 / 2, requiredTechnologyShortnames: [] ),
        Component(shortName: .CommHub, name: "Communications Hub", description: "A surface level communications hub. This provides redundant communications on the Mars surface as well as with Earth. The big advantage is very low latency for local (surface) based communication and persistence of data too large to transmit through space.", cost: 750_000_000, buildTime: 365, requiredTechnologyShortnames: [] ),
        Component(shortName: .Lander, name: "Mars Lander", description: "The most complex part of this stage is to build this Lander. It needs to survive the landing on the surface, needs to withstand cosmic radiation AND function automatically. It also has the major task of validating all potential spots for the Mars colony.", cost: 1_500_000_000, buildTime: 365 * 2, requiredTechnologyShortnames: [] ),
        Component(shortName: .Rocket_L_1, name: "Large rocket", description: "These rockets are the cargo ferring backbone of any mission that aspires to bring people to Mars. Despite its very large bulk, it is still quite affordable and quick to build.", cost: 1_000_000_000, buildTime: 365 / 2, requiredTechnologyShortnames: []),
        Component(shortName: .Rocket_L_2, name: "Large rocket", description: "These rockets are the cargo ferring backbone of any mission that aspires to bring people to Mars. Despite its very large bulk, it is still quite affordable and quick to build.", cost: 1_000_000_000, buildTime: 365 / 2, requiredTechnologyShortnames: []),
        Component(shortName: .Rocket_L_3, name: "Large rocket", description: "These rockets are the cargo ferring backbone of any mission that aspires to bring people to Mars. Despite its very large bulk, it is still quite affordable and quick to build.", cost: 1_000_000_000, buildTime: 365 / 2, requiredTechnologyShortnames: []),
        Component(shortName: .Moxie, name: "Moxie", description: "Moxies extract oxygen from the Mars atmosphere and soil (regolith).", cost: 300_000_000, buildTime: 365, requiredTechnologyShortnames: []),
        Component(shortName: .WaterExtractor, name: "Water Extractor", description: "Water extractors extract water from the Mars soil (regolith). This means they work almost anywhere on the Mars surface: they are not dependant on ice deposits. There output is limited though. To support prolonged stay on Mars as well as larger colonies, sources of actual water (ice) are required.", cost: 250_000_000, buildTime: 365, requiredTechnologyShortnames: []),
        Component(shortName: .SolarPanel, name: "Solar Panel Array", description: "Power is essential to operate any equipment on Mars. These panels come with ample batteries.", cost: 250_000_000, buildTime: 365 / 2, requiredTechnologyShortnames: []),
        Component(shortName: .Warehouse, name: "Storage warehouse", description: "This warehouse is a basic shelter for equipment when it is not in use. It also provides a basic habitat and functionality such as a 3D printer for spare parts.", cost: 100_000_000, buildTime: 365 / 2, requiredTechnologyShortnames: []),
        Component(shortName: .Car, name: "Car", description: "The quickest and most convenient way to cover large distances on the Mars soil, within the limits of its 30MPH top speed. It should cover most terrain types, provides a pressurised environment and limited radiation shielding.", cost: 5_000_000, buildTime: 365 / 2, requiredTechnologyShortnames: []),
        Component(shortName: .Supplies, name: "Supplies", description: "With the complexity of all the other parts, ammassing the required supplies is actually unexpectatly easy (and cheap)", cost: 10_000_000, buildTime: 365 / 4, requiredTechnologyShortnames: []),
        Component(shortName: .Habitat, name: "Dome based habitat", description: "The Dome will be the colonies primary habitat. Initially it's only ferried to Mars, it will be setup on a suitable location by the first group of colonists.", cost: 10_000_000, buildTime: 365 / 4, requiredTechnologyShortnames: []),
        Component(shortName: .Rocket_M_v2, name: "(Improved) medium size rocket", description: "This second iteration of the medium size rocket is intented for actual crew transport, meaning it has three requirements: 1) sustain humans for the duration of the flight to (and from) Mars, 2) land on Mars and 3) be able to return with the crew to Earth if so required. The build time includes the time required for a flight to Mars and back.", cost: 500_000_000, buildTime: 365 * 2, requiredTechnologyShortnames: []),
        Component(shortName: .CrewQuarters_MO, name: "Crew quarters (beta)", description: "An early version of the eventual crew quarters. It's filled to the brim with sensors to determine whether the final crew quarters are able to sustain human life for the trip to Mars and back.", cost: 500_000_000, buildTime: 365 * 2, requiredTechnologyShortnames: []),
        Component(shortName: .CrewQuarters, name: "Crew quarters", description: "The tests with the earlier version gave invaluable information for improvements. These quarters will be the home for your crew for the trip to Mars and (if required) back.", cost: 250_000_000, buildTime: 365, requiredTechnologyShortnames: []),
        Component(shortName: .Crew, name: "Mission crew", description: "These brave people could be the first people to walk on Mars, or die trying. Do not underestimate the difficulty in finding the right crew (and associated cost)", cost: 500_000_000, buildTime: 365, requiredTechnologyShortnames: [])
    ]
    
    public static func getComponentByName(_ shortName: ShortName) -> Component? {
        return allComponents.first(where: { c in c.shortName == shortName })
    }
    
    public static func == (lhs: Component, rhs: Component) -> Bool {
        return lhs.shortName == rhs.shortName
    }
    
    public let shortName: ShortName
    public let name: String
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
    
    public func startBuild(startDate: Date) throws -> Component {
        guard buildStartedOn == nil else {
            throw ComponentError.componentAlreadyBeingBuilt
        }
        
        var startedBuiltComponent = self
        startedBuiltComponent.buildStartedOn = startDate
        return startedBuiltComponent
    }
    
    public func updateComponent(ticks: Int = 1) -> Component {
        var updatedComponent = self
        if buildStartedOn != nil {
            updatedComponent.percentageCompleted += 100.0 * Double(ticks) / Double(buildTime)
        }
        
        if updatedComponent.percentageCompleted > 100.0 {
            updatedComponent.percentageCompleted = 100.0
        }
        
        return updatedComponent
    }
    
    public func playerHasPrerequisitesForComponent(_ player: Player) -> Bool {
        for prereq in requiredTechnologyShortnames {
            if player.unlockedTechnologyNames.contains(prereq) == false {
                return false
            }
        }
        
        // all prerequisites met.
        return true
    }
}

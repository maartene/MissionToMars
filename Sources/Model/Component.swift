//
//  Component.swift
//  App
//
//  Created by Maarten Engels on 22/12/2019.
//

import Foundation

struct Component {
    
    enum ShortName: String, CaseIterable {
        case Rocket_S
        case MissionControl
        case Satellite
    }
    
    enum ComponentError: Error {
        case unknownShortName
    }
    
    static let allComponents = [
        Component(shortName: .Rocket_S, name: "Small reusable rocket", description: "Although it is technically possible to reach Mars without reusable rockets, considering the large number of flights required the cost would be prohibitive. Although this first reusable rocket will be more expensive than a single use rocket, the subsequent ones will be much MUCH cheaper.", cost: 2_000_000_000, buildTime: 365),
        Component(shortName: .MissionControl, name: "Mission Control", description: "All your missions will be guided from here. You only need to build one once, these are the initial costs. It will be upgraded as per technological advancements. It will also receive upgrades when building subsequent components.", cost: 1_000_000_000, buildTime: 365 / 2),
        Component(shortName: .Satellite, name: "Mars Orbital Satellite", description: "This sattelite has three major purposes: \n1) Provide imagery of Mars surface to help find suitable spot for colony \n2) Provide local communation \n3) Provide a beach head for communication with surface deployments", cost: 1_000_000_000, buildTime: 3 * 365 / 4 )
    ]
    
    static func getComponentByName(_ shortName: ShortName) -> Component? {
        return allComponents.first(where: { c in c.shortName == shortName })
    }
    
    let shortName: ShortName
    let name: String
    let description: String
    let cost: Double
    let buildTime: Int // in days/ticks
    var buildStartedOn: Date?
    var percentageCompleted: Double = 0
    
    func startBuild(startDate: Date) -> Component {
        var startedBuiltComponent = self
        startedBuiltComponent.buildStartedOn = Date()
        return startedBuiltComponent
    }
    
    func updateComponent(ticks: Int = 1) -> Component {
        var updatedComponent = self
        updatedComponent.percentageCompleted += 100.0 * Double(ticks) / Double(buildTime)
        return updatedComponent
    }
}

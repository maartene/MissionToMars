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
        case MissionControl
        case Satellite
    }
    
    public enum ComponentError: Error {
        case unknownShortName
        case componentAlreadyBeingBuilt
    }
    
    public static let allComponents = [
        Component(shortName: .Rocket_S, name: "Small reusable rocket", description: "Although it is technically possible to reach Mars without reusable rockets, considering the large number of flights required the cost would be prohibitive. Although this first reusable rocket will be more expensive than a single use rocket, the subsequent ones will be much MUCH cheaper.", cost: 2_000_000_000, buildTime: 365),
        Component(shortName: .MissionControl, name: "Mission Control", description: "All your missions will be guided from here. You only need to build one once, these are the initial costs. It will be upgraded as per technological advancements. It will also receive upgrades when building subsequent components.", cost: 1_000_000_000, buildTime: 365 / 2),
        Component(shortName: .Satellite, name: "Mars Orbital Satellite", description: "This sattelite has three major purposes: \n1) Provide imagery of Mars surface to help find suitable spot for colony \n2) Provide local communation \n3) Provide a beach head for communication with surface deployments", cost: 1_000_000_000, buildTime: 3 * 365 / 4 )
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
}

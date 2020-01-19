//
//  Stage.swift
//  App
//
//  Created by Maarten Engels on 22/12/2019.
//

import Foundation

public struct Stage: Equatable, Codable {
    public static let allStages: [Stage] = [
        Stage(level: 1, name: "Orbital Satellite", description: "The first step in your Mars mission will be to send an orbital satellite to Mars. This will prove your capability in reaching Mars, as well as provide valuable information from the Mars surface. In later stages, you will be able to use the satellite for communicating with the surface.", components: [Component.getComponentByName(.Rocket_S)!, Component.getComponentByName(.MissionControl)!, Component.getComponentByName(.Satellite)!]),
        Stage(level: 2, name: "Unmanned lander", description: "The second step is to bring an unmanned lander to Mars. This has been done before, but is still very challenging. You should be able to do this before trying to send living people to Mars. Also, the lander will provide invuluable intel, more so than the satellite can provide.", components: [Component.getComponentByName(.Rocket_M)!, Component.getComponentByName(.CommHub)!, Component.getComponentByName(.Lander)!]),
        Stage(level: 3, name: "Cargo!", description: "Welcome to the most expensive and time consuming part of the Mars mission: getting all the required cargo to Mars. In particular, you should provide everything required for a basic colony: water, power and oxygen production. Storage and workplaces and a way to get around. This will require several rocket trips to complete.", components: [Component.getComponentByName(.Rocket_L_1)!, Component.getComponentByName(.Rocket_L_2)!, Component.getComponentByName(.Rocket_L_3)!, Component.getComponentByName(.Moxie)!, Component.getComponentByName(.WaterExtractor)!, Component.getComponentByName(.SolarPanel)!, Component.getComponentByName(.Warehouse)!, Component.getComponentByName(.Car)!, Component.getComponentByName(.Supplies)!, Component.getComponentByName(.Habitat)!]),
        Stage(level: 4, name: "Proof-of-concept return flight", description: "Although the first crew to set foot on Mars are intended to create a permanent colony, if all else fails, they should be able to return to Earth. This stage is intented to show that you can get people to Mars AND BACK!", components: [Component.getComponentByName(.Rocket_M_v2)!, Component.getComponentByName(.CrewQuarters_MO)!]),
        Stage(level: 5, name: "Initial colony", description: "You got this far! Now's the time to select your actual crew and send them to the red planet. Fingers crossed they make it there alive and stay alive.", components: [Component.getComponentByName(.Rocket_M_v2)!, Component.getComponentByName(.CrewQuarters)!, Component.getComponentByName(.Crew)!])
    ]
    
    public static func == (lhs: Stage, rhs: Stage) -> Bool {
        return lhs.level == rhs.level
    }
    
    public enum StageError: Error {
        case invalidStageLevel
        case componentNotInStage
        case alreadyBuildingComponent
    }
    
    public static func getStageByLevel(_ level: Int) throws -> Stage {
        guard let stage = allStages.first(where: {s in s.level == level }) else {
            throw StageError.invalidStageLevel
        }
        
        return stage
    }
    
    public let level: Int
    public let name: String
    public let description: String
    public private(set) var components: [Component]
    
    public var uncompletedComponents: [Component] {
        return components.filter { component in component.percentageCompleted < 100 }
    }
    
    public var currentlyBuildingComponent: Component? {
        return uncompletedComponents.first { component in component.buildStartedOn != nil }
    }
    
    public var unstartedComponents: [Component] {
        return uncompletedComponents.filter { component in component.buildStartedOn == nil && component.percentageCompleted < 100.0 }
    }
    
    public var percentageComplete: Double {
        var sum = 0.0
        for component in components {
            sum += component.percentageCompleted
        }
        return sum / Double(components.count)
    }
    
    public var completedComponents: [Component] {
        return components.filter { component in
            component.percentageCompleted >= 100.0
        }
    }
    
    public func updateStage(ticks: Int = 1) -> Stage {
        let updatedComponents = self.components.map { component in
            component.updateComponent(ticks: ticks)
        }
        
        var updatedStage = self
        updatedStage.components = updatedComponents
        return updatedStage
    }
    
    public func startBuildingComponent(_ component: Component, buildDate: Date, buildTimeFactor: Double = 1.0) throws -> Stage {
        var updatedStage = self
        
        guard currentlyBuildingComponent == nil else {
            throw StageError.alreadyBuildingComponent
        }
        
        guard components.contains(component) else {
            throw StageError.componentNotInStage
        }
        
        var updatedComponents = components
        
        if let componentIndex = updatedComponents.firstIndex(of: component) {
            updatedComponents[componentIndex] = try component.startBuild(startDate: buildDate, buildTimeFactor: buildTimeFactor)
        }
         
        updatedStage.components = updatedComponents
        
        return updatedStage
    }
    
    public var stageComplete: Bool {
        return uncompletedComponents.count == 0
    }
}

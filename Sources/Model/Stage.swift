//
//  Stage.swift
//  App
//
//  Created by Maarten Engels on 22/12/2019.
//

import Foundation

public struct Stage: Equatable, Codable {
    public static let allStages = [
        Stage(level: 1, name: "Orbital Satellite", description: "The first step in your Mars mission will be to send an orbital satellite to Mars. This will prove your capability in reaching Mars, as well as provide valuable information from the Mars surface. In later stages, you will be able to use the satellite for communicating with the surface.", components: [Component.getComponentByName(.Rocket_S)!, Component.getComponentByName(.MissionControl)!, Component.getComponentByName(.Satellite)!])
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
        return uncompletedComponents.filter { component in component.buildStartedOn == nil }
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
    
    public func startBuildingComponent(_ component: Component, buildDate: Date) throws -> Stage {
        var updatedStage = self
        
        guard currentlyBuildingComponent == nil else {
            throw StageError.alreadyBuildingComponent
        }
        
        guard components.contains(component) else {
            throw StageError.componentNotInStage
        }
        
        var updatedComponents = components
        
        if let componentIndex = updatedComponents.firstIndex(of: component) {
            updatedComponents[componentIndex] = try component.startBuild(startDate: buildDate)
        }
         
        updatedStage.components = updatedComponents
        
        return updatedStage
    }
    
    public var stageComplete: Bool {
        return uncompletedComponents.count == 0
    }
}

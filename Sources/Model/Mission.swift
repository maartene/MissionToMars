//
//  Mission.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation
import FluentSQLite
import Vapor

public struct Mission: Content {
    public enum MissionError: Error {
        case uncompletedComponents
    }
    
    public var id = UUID()
    
    public var missionName: String// = "Mission To Mars"// #\(Int.random(in: 1...1_000_000))"
    public let owningPlayerID: UUID
    
    public var percentageDone: Double {
        var sum = 0.0
        for stage in stages {
            sum += stage.percentageComplete
        }
        return sum / Double(stages.count)
    }
    
    public private(set) var stages: [Stage]
    public private(set) var currentStageLevel = 1
    
    public var currentStage: Stage {
        guard let stage = stages.first(where: { stage in stage.level == currentStageLevel }) else {
            fatalError("No stage found with currentStageLevel: \(currentStageLevel) in array of stages \(stages).")
        }
        return stage
    }
    
    public init(owningPlayerID: UUID) {
        self.owningPlayerID = owningPlayerID
        self.missionName = "Mission To Mars #\(Int.random(in: 1...1_000_000))"
        self.stages = Stage.allStages
    }
    
    public func startBuildingInStage(_ component: Component, buildDate: Date, by player: Player) throws -> Mission {
        let changedStage = try currentStage.startBuildingComponent(component, buildDate: buildDate, by: player)
        
        let stageIndex = stages.firstIndex(of: changedStage)!
        var changedStages = stages
        changedStages[stageIndex] = changedStage
            
        var changedMission = self
        changedMission.stages = changedStages
        return changedMission
    }
    
    public func updateMission(supportingPlayers: [Player]) -> Mission {
        var updatedMission = self
        
        let updatedStages = stages.map { stage in
            stage.updateStage(supportingPlayers: supportingPlayers)
        }
        
        updatedMission.stages = updatedStages
        
        return updatedMission
    }
    
    public func goToNextStage() throws -> Mission {
        var updatedMission = self
        
        guard currentStage.uncompletedComponents.count == 0 else {
            throw MissionError.uncompletedComponents
        }
        
        updatedMission.currentStageLevel += 1
        
        if updatedMission.currentStageLevel > Stage.allStages.count {
            print("You won the game!")
            updatedMission.currentStageLevel = Stage.allStages.count
        }
        
        return updatedMission
    }
    
    public var missionComplete: Bool {
        return currentStageLevel == Stage.allStages.count && currentStage.uncompletedComponents.count == 0
    }
    
    func getSupportingPlayers(from allPlayers: [Player]) -> [Player] {
        var result = [Player]()
        if let owner = allPlayers.first(where: {$0.id == owningPlayerID}) {
            result.append(owner)
            
            let supportingPlayers = allPlayers.filter { player in player.supportsPlayerID == owner.id}
            result.append(contentsOf: supportingPlayers)
        }
        
        return result
    }
}

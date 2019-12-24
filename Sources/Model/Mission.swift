//
//  Mission.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation
import FluentSQLite
import Vapor

public struct Mission: Content, SQLiteUUIDModel {
    public enum MissionError: Error {
        case uncompletedComponents
    }
    
    public var id: UUID?
    
    public var missionName: String// = "Mission To Mars"// #\(Int.random(in: 1...1_000_000))"
    public let owningPlayerID: UUID
    
    public var percentageDone: Double {
        var sum = 0.0
        for stage in stages {
            sum += stage.percentageComplete
        }
        return sum / Double(stages.count)
    }
    public var successChance: Double = 0
    
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
    
    public func startBuildingInStage(_ component: Component, buildDate: Date) throws -> Mission {
        let changedStage = try currentStage.startBuildingComponent(component, buildDate: buildDate)
        
        let stageIndex = stages.firstIndex(of: changedStage)!
        var changedStages = stages
        changedStages[stageIndex] = changedStage
            
        var changedMission = self
        changedMission.stages = changedStages
        return changedMission
    }
    
    public func updateMission(ticks: Int = 1) -> Mission {
        var updatedMission = self
        
        let updatedStages = stages.map { stage in
            stage.updateStage(ticks: ticks)
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
}

extension Mission: Migration { }

extension Mission {
    public static func saveMissions(_ missions: [Mission], on conn: DatabaseConnectable) -> Future<[Mission]> {
        let futures = missions.map { mission in
            return mission.update(on: conn)
        }
        return futures.flatten(on: conn)
    }
        
    public func getOwningPlayer(on conn: DatabaseConnectable) throws -> Future<Player> {
        return Player.find(owningPlayerID, on: conn).map(to: Player.self) { player in
            guard let player = player else {
                throw Player.PlayerError.userDoesNotExist
            }
            
            return player
        }
    }
}

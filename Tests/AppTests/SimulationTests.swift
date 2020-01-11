//
//  SimulationTests.swift
//  MissionToMars
//
//  Created by Maarten Engels on 15/12/2019.
//

import Foundation
import Dispatch
import XCTest
@testable import Model

final class SimulationTests : XCTestCase {
    func testAdvanceSimulationWithLargeEnoughTimeDifference() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60), players: [], missions: [])
        
        XCTAssertGreaterThan(update.updatedSimulation.tickCount, simulation.tickCount, " ticks")
        XCTAssertGreaterThan(update.updatedSimulation.gameDate, simulation.gameDate, " gameDate")
        XCTAssertGreaterThan(update.updatedSimulation.nextUpdateDate, simulation.nextUpdateDate, " nextUpdateDate")
        XCTAssertEqual(update.updatedSimulation.id, simulation.id, "after update, UUIDs should be the same.")
    }
    
    func testSimulationDoesNotAdvanceWithSmallEnoughTimeDifference() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60))
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 30), players: [], missions: [])
        
        XCTAssertEqual(update.updatedSimulation.tickCount, simulation.tickCount, " ticks")
        XCTAssertEqual(update.updatedSimulation.gameDate, simulation.gameDate, " gameDate")
        XCTAssertEqual(update.updatedSimulation.nextUpdateDate, simulation.nextUpdateDate, " nextUpdateDate")
    }
    
    func testAdvanceSimulationMultipleTicks() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60 * 4), players: [], missions: [])
        
        XCTAssertEqual(update.updatedSimulation.tickCount, 5, " ticks")
    }
    
    func testUpdatePlayer() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        let players = [Player(username: "testUser")]
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60 * 4), players: players, missions: [])
        
        XCTAssertGreaterThan(update.updatedPlayers[0].cash, players[0].cash, " cash")
        XCTAssertEqual(update.updatedPlayers[0].id, players[0].id, "Player.id should be the same after update.")
    }
    
    func testUpdateMission() throws {
        let gameDate = Date().addingTimeInterval(Double(SECONDS_IN_YEAR))
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        let mission = Mission(owningPlayerID: UUID())
        let component = mission.currentStage.components.first!
        let buildingMission = try mission.startBuildingInStage(component, buildDate: Date())
        
        let missions = [buildingMission]
        
        let updatedSimulationResult = simulation.updateSimulation(currentDate: Date(), players: [], missions: missions)
        let updatedMission = updatedSimulationResult.updatedMissions.first!
        XCTAssertGreaterThan(updatedMission.percentageDone, mission.percentageDone)
        XCTAssertGreaterThan(updatedMission.currentStage.percentageComplete, mission.currentStage.percentageComplete)
        XCTAssertGreaterThan(updatedMission.currentStage.currentlyBuildingComponent?.percentageCompleted ?? 0, mission.currentStage.currentlyBuildingComponent?.percentageCompleted ?? 0)
        
    }
    
    func testUpdateAdvancesPlayerImprovementBuildProgress() throws {
        let gameDate = Date().addingTimeInterval(Double(SECONDS_IN_YEAR))
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        
        var player = Player(username: "testUser")
        let improvement = Improvement.getImprovementByName(.Faculty)!
        player.debug_setCash(improvement.cost)
        let buildingPlayer = try player.startBuildImprovement(improvement, startDate: gameDate)
        
        let updateResult = simulation.updateSimulation(currentDate: Date(), players: [buildingPlayer], missions: [])
        XCTAssertGreaterThan(updateResult.updatedPlayers[0].improvements.last!.percentageCompleted, buildingPlayer.improvements.last!.percentageCompleted, "%")
    }
    
    func testUpdateTriggersImprovementEffectInPlayer() throws {
        let gameDate = Date().addingTimeInterval(Double(SECONDS_IN_YEAR))
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        
        let improvement = Improvement.getImprovementByName(.PrefabFurniture)!
        var player = try Player(username: "testUser").extraIncome(amount: improvement.cost).startBuildImprovement(improvement, startDate: Date())
        let extraCash = player.cashPerTick
        
        player = player.updatePlayer(ticks: improvement.buildTime + 1)
        XCTAssert(player.completedImprovements.contains(improvement))
        
        let updateResult = simulation.updateSimulation(currentDate: Date(), players: [player], missions: [])
        XCTAssertGreaterThan(updateResult.updatedPlayers[0].cash, player.cash + extraCash, " cash")
    }

    static let allTests = [
        ("testAdvanceSimulationWithLargeEnoughTimeDifference", testAdvanceSimulationWithLargeEnoughTimeDifference),
        ("testSimulationDoesNotAdvanceWithSmallEnoughTimeDifference", testSimulationDoesNotAdvanceWithSmallEnoughTimeDifference),
        ("testAdvanceSimulationMultipleTicks", testAdvanceSimulationMultipleTicks),
        ("testUpdatePlayer", testUpdatePlayer),
        ("testUpdateMission", testUpdateMission),
        ("testUpdateAdvancesPlayerImprovementBuildProgress", testUpdateAdvancesPlayerImprovementBuildProgress),
        ("testUpdateTriggersImprovementEffectInPlayer", testUpdateTriggersImprovementEffectInPlayer),
    ]
}

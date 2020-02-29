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
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60))
        
        XCTAssertGreaterThan(update.tickCount, simulation.tickCount, " ticks")
        XCTAssertGreaterThan(update.gameDate, simulation.gameDate, " gameDate")
        XCTAssertGreaterThan(update.nextUpdateDate, simulation.nextUpdateDate, " nextUpdateDate")
        XCTAssertEqual(update.id, simulation.id, "after update, UUIDs should be the same.")
    }
    
    func testSimulationDoesNotAdvanceWithSmallEnoughTimeDifference() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60))
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 30))
        
        XCTAssertEqual(update.tickCount, simulation.tickCount, " ticks")
        XCTAssertEqual(update.gameDate, simulation.gameDate, " gameDate")
        XCTAssertEqual(update.nextUpdateDate, simulation.nextUpdateDate, " nextUpdateDate")
    }
    
    func testAdvanceSimulationMultipleTicks() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60 * 4))
        
        // if this fails, it is usually because simulation update time was hardcoded to a different value (in 'Simulation.swift')
        XCTAssertEqual(update.tickCount, 5, " ticks")
    }
    
    func testUpdatePlayer() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        var simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        simulation = try simulation.createPlayer(emailAddress: "example@example.com", name: "testUser").updatedSimulation
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60 * 4))
        
        XCTAssertGreaterThan(update.players[0].cash, simulation.players[0].cash, " cash")
        XCTAssertEqual(update.players[0].id, simulation.players[0].id, "Player.id should be the same after update.")
    }
    
    func testUpdateMission() throws {
        let gameDate = Date().addingTimeInterval(Double(SECONDS_IN_YEAR))
        var simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        let playerCreateResult = try simulation.createPlayer(emailAddress: "test@test.com", name: "test")
        var player = playerCreateResult.newPlayer
        
        simulation = playerCreateResult.updatedSimulation
        simulation = try simulation.createMission(for: playerCreateResult.newPlayer)
        let mission = simulation.missions[0]
        let component = mission.currentStage.components.first!
        player = player.extraIncome(amount: component.cost)
        simulation = try simulation.replacePlayer(player)
        let buildingMission = try mission.startBuildingInStage(component, buildDate: Date(), by: player)
        
        simulation = try simulation.replaceMission(buildingMission)
        
        let updatedSimulation = simulation.updateSimulation(currentDate: Date())
        XCTAssertGreaterThan(updatedSimulation.tickCount, simulation.tickCount, "ticks")
        let updatedMission = updatedSimulation.missions.first!
        XCTAssertGreaterThan(updatedMission.percentageDone, mission.percentageDone)
        XCTAssertGreaterThan(updatedMission.currentStage.percentageComplete, mission.currentStage.percentageComplete)
        XCTAssertGreaterThan(updatedMission.currentStage.currentlyBuildingComponents.first?.percentageCompleted ?? 0, mission.currentStage.currentlyBuildingComponents.first?.percentageCompleted ?? 0)
        
    }
    
    func testUpdateAdvancesPlayerImprovementBuildProgress() throws {
        let gameDate = Date().addingTimeInterval(Double(SECONDS_IN_YEAR))
        var simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        let createPlayerResult = try simulation.createPlayer(emailAddress: "example@example.com", name: "testUser")
        simulation = createPlayerResult.updatedSimulation
        var player = createPlayerResult.newPlayer
        let improvement = Improvement.getImprovementByName(.Faculty)!
        player.debug_setCash(improvement.cost)
        let buildingPlayer = try player.startBuildImprovement(improvement, startDate: gameDate)
        
        let updateResult = simulation.updateSimulation(currentDate: Date())
        XCTAssertGreaterThan(updateResult.players[0].improvements.last!.percentageCompleted, buildingPlayer.improvements.last!.percentageCompleted, "%")
    }
    
    func testUpdateTriggersImprovementEffectInPlayer() throws {
        let gameDate = Date().addingTimeInterval(Double(SECONDS_IN_YEAR))
        var simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        
        let improvement = Improvement.getImprovementByName(.PrefabFurniture)!
        
        let createPlayerResult = try simulation.createPlayer(emailAddress: "example@example.com", name: "testUser")
        simulation = createPlayerResult.updatedSimulation
        var player = createPlayerResult.newPlayer
        
        player = unlockTechnologiesForImprovement(player: player, improvement: improvement)
        player = try player.startBuildImprovement(improvement, startDate: Date())
        let extraCash = player.cashPerTick
        
        player = player.updatePlayer(ticks: improvement.buildTime + 1)
        XCTAssert(player.completedImprovements.contains(improvement))
        
        let updateResult = simulation.updateSimulation(currentDate: Date())
        XCTAssertGreaterThan(updateResult.players[0].cash, player.cash + extraCash, " cash")
    }
    
    func unlockTechnologiesForImprovement(player: Player, improvement: Improvement) -> Player {
        var changedPlayer = player
        for tech in improvement.requiredTechnologyShortnames {
            changedPlayer.forceUnlockTechnology(shortName: tech)
        }
        return changedPlayer
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

//
//  SimulationTests.swift
//  MissionToMars
//
//  Created by Maarten Engels on 15/12/2019.
//

import Foundation
import Dispatch
import XCTest
@testable import App

final class SimulationTests : XCTestCase {
    func testAdvanceSimulationWithLargeEnoughTimeDifference() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(UPDATE_INTERVAL_IN_MINUTES * 60))
        
        XCTAssertGreaterThan(update.tickCount, simulation.tickCount, " ticks")
        XCTAssertGreaterThan(update.gameDate, simulation.gameDate, " gameDate")
        XCTAssertGreaterThan(update.nextUpdateDate, simulation.nextUpdateDate, " nextUpdateDate")
        XCTAssertEqual(update.id, simulation.id, "after update, UUIDs should be the same.")
    }
    
    func testSimulationDoesNotAdvanceWithSmallEnoughTimeDifference() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date().addingTimeInterval(UPDATE_INTERVAL_IN_MINUTES * 60), createDefaultAdminPlayer: true)
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(UPDATE_INTERVAL_IN_MINUTES * 30))
        
        XCTAssertEqual(update.tickCount, simulation.tickCount, " ticks")
        XCTAssertEqual(update.gameDate, simulation.gameDate, " gameDate")
        XCTAssertEqual(update.nextUpdateDate, simulation.nextUpdateDate, " nextUpdateDate")
    }
    
    func testAdvanceSimulationMultipleTicks() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(UPDATE_INTERVAL_IN_MINUTES * 60 * 4))
        
        // if this fails, it is usually because simulation update time was hardcoded to a different value (in 'Simulation.swift')
        XCTAssertEqual(update.tickCount, 5, " ticks")
    }
    
    func testUpdatePlayer() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        var simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        simulation = try simulation.createPlayer(emailAddress: "example@example.com", name: "testUser").updatedSimulation
        let update = simulation.updateSimulation(currentDate: Date().addingTimeInterval(UPDATE_INTERVAL_IN_MINUTES * 60 * 4))
        
        XCTAssertGreaterThan(update.players[0].cash, simulation.players[0].cash, " cash")
        XCTAssertEqual(update.players[0].id, simulation.players[0].id, "Player.id should be the same after update.")
    }
    
    func testUpdateMission() throws {
        let gameDate = Date().addingTimeInterval(Double(SECONDS_IN_YEAR))
        var simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date(), createDefaultAdminPlayer: true)
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
        var simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        let createPlayerResult = try simulation.createPlayer(emailAddress: "example@example.com", name: "testUser")
        simulation = createPlayerResult.updatedSimulation
        var player = createPlayerResult.newPlayer
        let improvement = Improvement.getImprovementByName(.Faculty)!
        player.debug_setCash(improvement.cost)
        let buildingPlayer = try player.startBuildImprovement(improvement, startDate: gameDate)
        
        let updateResult = simulation.updateSimulation(currentDate: Date())
        XCTAssertGreaterThan(updateResult.players[0].improvements.last!.percentageCompleted, buildingPlayer.improvements.last!.percentageCompleted, "%")
    }
    
    func playerCompleteImprovement(player: Player, improvement: Improvement) -> Player {
        var resultPlayer = player
        for _ in 0 ... improvement.buildTime {
            resultPlayer = resultPlayer.updatePlayer()
        }
        return resultPlayer
    }
    
    func testUpdateTriggersImprovementEffectInPlayer() throws {
        let gameDate = Date().addingTimeInterval(Double(SECONDS_IN_YEAR))
        var simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        
        let improvement = Improvement.getImprovementByName(.PrefabFurniture)!
        
        let createPlayerResult = try simulation.createPlayer(emailAddress: "example@example.com", name: "testUser")
        simulation = createPlayerResult.updatedSimulation
        var player = createPlayerResult.newPlayer
        
        player = try player.startBuildImprovement(improvement, startDate: Date(), options: [.ignoreTechPrereqs])
        let extraCash = player.cashPerTick
        
        player = playerCompleteImprovement(player: player, improvement: improvement)
        XCTAssert(player.completedImprovements.contains(improvement))
        
        let updateResult = simulation.updateSimulation(currentDate: Date())
        XCTAssertGreaterThan(updateResult.players[0].cash, player.cash + extraCash, " cash")
    }
    
    func testPlayerInvestsInComponent() throws {
        let gameDate = Date().addingTimeInterval(Double(SECONDS_IN_YEAR))
        var simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        let playerCreateResult = try simulation.createPlayer(emailAddress: "test@test.com", name: "test")
        var player = playerCreateResult.newPlayer
        simulation = playerCreateResult.updatedSimulation
        
        simulation = try simulation.createMission(for: player)
        let mission = simulation.missions[0]
        XCTAssertEqual(mission.currentStage.currentlyBuildingComponents.count, 0)
        
        let component = mission.currentStage.components.first!
        player = simulation.players.last!
        player = unlockTechnologiesForComponent(player: player, component: component)
        player = player.extraIncome(amount: component.cost)
        simulation = try simulation.replacePlayer(player)
        let buildingSimulation = try simulation.playerInvestsInComponent(player: player, component: component)
        let buildingMission = buildingSimulation.missions[0]
        
        XCTAssertTrue(buildingMission.currentStage.currentlyBuildingComponents.contains(component))
    }
    
    func testDonateCashToPlayerInSameMission() throws {
        // public func donateToPlayerInSameMission(donatingPlayer: Player, receivingPlayer: Player, techPoints: Int)
        
        var simulation = Simulation(tickCount: 0, gameDate: Date(), nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        
        let playerCreateResult1 = try simulation.createPlayer(emailAddress: "test1@test.com", name: "test1")
        var player1 = playerCreateResult1.newPlayer
        simulation = playerCreateResult1.updatedSimulation
        
        let playerCreateResult2 = try simulation.createPlayer(emailAddress: "test2@test.com", name: "test2")
        var player2 = playerCreateResult2.newPlayer
        simulation = playerCreateResult2.updatedSimulation
        
        simulation = try simulation.createMission(for: player1)
        player1 = simulation.players[1]
        player2.supportsPlayerID = player1.id
        simulation = try simulation.replacePlayer(player2)
        
        let donationResult = try simulation.donateToPlayerInSameMission(donatingPlayer: player1, receivingPlayer: player2, cash: player1.cash)
        
        XCTAssertLessThan(donationResult.players[1].cash, player1.cash, "cash")
        XCTAssertGreaterThan(donationResult.players[2].cash, player2.cash, "cash")
        
    }
    
    func testDonateTechToPlayerInSameMission() throws {
        var simulation = Simulation(tickCount: 0, gameDate: Date(), nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        
        let playerCreateResult1 = try simulation.createPlayer(emailAddress: "test1@test.com", name: "test1")
        var player1 = playerCreateResult1.newPlayer
        simulation = playerCreateResult1.updatedSimulation
        
        let playerCreateResult2 = try simulation.createPlayer(emailAddress: "test2@test.com", name: "test2")
        var player2 = playerCreateResult2.newPlayer
        simulation = playerCreateResult2.updatedSimulation
        
        simulation = try simulation.createMission(for: player1)
        player1 = simulation.players[1]
        player2.supportsPlayerID = player1.id
        simulation = try simulation.replacePlayer(player2)
        
        let donationResult = try simulation.donateToPlayerInSameMission(donatingPlayer: player1, receivingPlayer: player2, techPoints: Int(player1.technologyPoints))
        
        XCTAssertLessThan(donationResult.players[1].technologyPoints, player1.technologyPoints, "techpoints")
        XCTAssertGreaterThan(donationResult.players[2].technologyPoints, player2.technologyPoints, "techpoints")
    }
    
    func testCreateMission() throws {
        var simulation = Simulation(tickCount: 0, gameDate: Date(), nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        
        let playerCreateResult = try simulation.createPlayer(emailAddress: "test1@test.com", name: "test1")
        let player = playerCreateResult.newPlayer
        simulation = playerCreateResult.updatedSimulation
        XCTAssertEqual(simulation.missions.count, 0, "missions")
        
        simulation = try simulation.createMission(for: player)
        XCTAssertNotNil(simulation.players[1].ownsMissionID)
        XCTAssertEqual(simulation.missions.count, 1, "missions")
    }
    
    func testReplacePlayer() throws {
        var simulation = Simulation(tickCount: 0, gameDate: Date(), nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        
        let playerCreateResult = try simulation.createPlayer(emailAddress: "test1@test.com", name: "test1")
        let player = playerCreateResult.newPlayer
        simulation = playerCreateResult.updatedSimulation
        
        let updatedPlayer = player.extraIncome(amount: 100)
        
        XCTAssertEqual(simulation.players[1].cash, player.cash, "cash")
        XCTAssertGreaterThan(updatedPlayer.cash, simulation.players[0].cash, "cash")
        
        simulation = try simulation.replacePlayer(updatedPlayer)
        
        XCTAssertEqual(simulation.players[1].cash, updatedPlayer.cash, "cash")
        XCTAssertGreaterThan(simulation.players[1].cash, player.cash, "cash")
        
    }
    
    func testReplaceMission() throws {
        var simulation = Simulation(tickCount: 0, gameDate: Date(), nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        
        let playerCreateResult = try simulation.createPlayer(emailAddress: "test1@test.com", name: "test1")
        let player = playerCreateResult.newPlayer
        simulation = playerCreateResult.updatedSimulation
        
        simulation = try simulation.createMission(for: player)
        let mission = simulation.missions[0]
        
        var changedMission = mission
        changedMission.missionName = "foo"
        
        XCTAssertEqual(simulation.missions[0].missionName, mission.missionName)
        XCTAssertNotEqual(changedMission.missionName, mission.missionName)
        
        simulation = try simulation.replaceMission(changedMission)
        
        XCTAssertEqual(simulation.missions[0].missionName, changedMission.missionName)
        XCTAssertNotEqual(simulation.missions[0].missionName, mission.missionName)
    }
    
    func testGetSupportedMissionForPlayer() throws {
        var simulation = Simulation(tickCount: 0, gameDate: Date(), nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        
        let playerCreateResult = try simulation.createPlayer(emailAddress: "test1@test.com", name: "test1")
        var player = playerCreateResult.newPlayer
        simulation = playerCreateResult.updatedSimulation
        
        simulation = try simulation.createMission(for: player)
        player = simulation.players[1]
        let mission = simulation.missions[0]
        let receivedMission = simulation.getSupportedMissionForPlayer(player)
        XCTAssertNotNil(receivedMission)
        XCTAssertEqual(simulation.getSupportedMissionForPlayer(player)?.id ?? UUID(), mission.id, "mission")
    }
    
    func testCreatePlayer() throws {
        var simulation = Simulation(tickCount: 0, gameDate: Date(), nextUpdateDate: Date(), createDefaultAdminPlayer: true)
        XCTAssertEqual(simulation.players.count, 1, "players")
        
        let playerCreateResult = try simulation.createPlayer(emailAddress: "test1@test.com", name: "test1")
        simulation = playerCreateResult.updatedSimulation
        XCTAssertEqual(simulation.players.count, 2, "players")
        XCTAssertEqual(simulation.players[1].id, playerCreateResult.newPlayer.id)
    }
    
    /*func unlockTechnologiesForImprovement(player: Player, improvement: Improvement) -> Player {
        var changedPlayer = player
        for tech in improvement.requiredTechnologyShortnames {
            //changedPlayer.forceUnlockTechnology(shortName: tech)
        }
        return changedPlayer
    }*/
    
    func unlockTechnologiesForComponent(player: Player, component: Component) -> Player {
        var changedPlayer = player
        for tech in component.requiredTechnologyShortnames {
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
        ("testPlayerInvestsInComponent", testPlayerInvestsInComponent),
        ("testDonateCashToPlayerInSameMission", testDonateCashToPlayerInSameMission),
        ("testDonateTechToPlayerInSameMission", testDonateTechToPlayerInSameMission),
        ("testCreateMission", testCreateMission),
        ("testReplacePlayer", testReplacePlayer),
        ("testReplaceMission", testReplaceMission),
        ("testGetSupportedMissionForPlayer", testGetSupportedMissionForPlayer),
        ("testCreatePlayer", testCreatePlayer),
    ]
}

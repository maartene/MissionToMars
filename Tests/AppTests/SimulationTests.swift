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
        let update = simulation.update(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60), players: [])
        
        XCTAssertGreaterThan(update.updatedSimulation.tickCount, simulation.tickCount, " ticks")
        XCTAssertGreaterThan(update.updatedSimulation.gameDate, simulation.gameDate, " gameDate")
        XCTAssertGreaterThan(update.updatedSimulation.nextUpdateDate, simulation.nextUpdateDate, " nextUpdateDate")
        XCTAssertEqual(update.updatedSimulation.id, simulation.id, "after update, UUIDs should be the same.")
    }
    
    func testSimulationDoesNotAdvanceWithSmallEnoughTimeDifference() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60))
        let update = simulation.update(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 30), players: [])
        
        XCTAssertEqual(update.updatedSimulation.tickCount, simulation.tickCount, " ticks")
        XCTAssertEqual(update.updatedSimulation.gameDate, simulation.gameDate, " gameDate")
        XCTAssertEqual(update.updatedSimulation.nextUpdateDate, simulation.nextUpdateDate, " nextUpdateDate")
    }
    
    func testAdvanceSimulationMultipleTicks() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        let update = simulation.update(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60 * 4), players: [])
        
        XCTAssertEqual(update.updatedSimulation.tickCount, 5, " ticks")
    }
    
    func testUpdatePlayer() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        let players = [Player(username: "testUser")]
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        let update = simulation.update(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60 * 4), players: players)
        
        XCTAssertGreaterThan(update.updatedPlayers[0].cash, players[0].cash, " cash")
        XCTAssertEqual(update.updatedPlayers[0].id, players[0].id, "Player.id should be the same after update.")
    }

    static let allTests = [
        ("testAdvanceSimulationWithLargeEnoughTimeDifference", testAdvanceSimulationWithLargeEnoughTimeDifference),
        ("testSimulationDoesNotAdvanceWithSmallEnoughTimeDifference", testSimulationDoesNotAdvanceWithSmallEnoughTimeDifference),
        ("testAdvanceSimulationMultipleTicks", testAdvanceSimulationMultipleTicks),
        ("testUpdatePlayer", testUpdatePlayer),
    ]
}

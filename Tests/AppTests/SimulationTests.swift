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
        let update = simulation.update(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60), updateAction: nil)
        
        XCTAssertGreaterThan(update.tickCount, simulation.tickCount, " ticks")
        XCTAssertGreaterThan(update.gameDate, simulation.gameDate, " gameDate")
        XCTAssertGreaterThan(update.nextUpdateDate, simulation.nextUpdateDate, " nextUpdateDate")
    }
    
    func testSimulationDoesNotAdvanceWithSmallEnoughTimeDifference() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60))
        let update = simulation.update(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 30), updateAction: nil)
        
        XCTAssertEqual(update.tickCount, simulation.tickCount, " ticks")
        XCTAssertEqual(update.gameDate, simulation.gameDate, " gameDate")
        XCTAssertEqual(update.nextUpdateDate, simulation.nextUpdateDate, " nextUpdateDate")
    }
    
    func testAdvanceSimulationMultipleTicks() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        let update = simulation.update(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60 * 4), updateAction: nil)
        
        XCTAssertEqual(update.tickCount, 5, " ticks")
    }
    
    func testCallUpdateFunction() throws {
        // let's assume gamedate is one year from now.
        let gameDate = Date().addingTimeInterval(24*60*60*365)
        
        var updateCounter = 0
        let updateFunction = { updateCounter += 1 }
        
        let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
        _ = simulation.update(currentDate: Date().addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60 * 4), updateAction: updateFunction)
        
        XCTAssertEqual(updateCounter, 5, " updates")
    }

    static let allTests = [
        ("testAdvanceSimulationWithLargeEnoughTimeDifference", testAdvanceSimulationWithLargeEnoughTimeDifference),
        ("testSimulationDoesNotAdvanceWithSmallEnoughTimeDifference", testSimulationDoesNotAdvanceWithSmallEnoughTimeDifference),
        ("testAdvanceSimulationMultipleTicks", testAdvanceSimulationMultipleTicks),
    ]
}

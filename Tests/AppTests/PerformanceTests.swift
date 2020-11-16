//
//  File.swift
//  
//
//  Created by Maarten Engels on 31/10/2020.
//

import Foundation
import XCTest

@testable import App

class PerformanceTests: XCTestCase {
    func testUpdateSimulation() throws {
        var simulation = Simulation(tickCount: 0, gameDate: Date(), nextUpdateDate: Date())
        print("Creating test players...")
        simulation = Simulation(tickCount: 0, gameDate: Date(), nextUpdateDate: Date())
        for i in 0 ..< 25 {
            //print("creating player \(i)")
            let result = try! simulation.createPlayer(emailAddress: "example_\(i)@example.com", name: "example_\(i)", password: "Foo")
            simulation = result.updatedSimulation
        }
        
        var run = 0
        measure {
            run += 1
            print("Starting run \(run).")
            var runSimulation = simulation
            for t in 0 ..< 10_000 {
                runSimulation = runSimulation.updateSimulation(currentDate: Date().addingTimeInterval(Double(t) * UPDATE_INTERVAL_IN_MINUTES * 60))
            }
        }
    }
}

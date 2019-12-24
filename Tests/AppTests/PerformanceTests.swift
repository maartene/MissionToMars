//
//  PerformanceTests.swift
//  AppTests
//
//  Created by Maarten Engels on 15/12/2019.
//

import App
import Dispatch
import Vapor
import XCTest
@testable import Model

final class PerformanceTests: XCTestCase {
    var app: Application!
    
    override func setUp() {
        do {
            var config = Config.default()
            var env = try Environment.detect()
            var services = Services.default()
            
            // this line clears the command-line arguments
            env.commandInput.arguments = []
            
            try App.configure(&config, &env, &services)
            
            app = try Application(
                config: config,
                environment: env,
                services: services
            )
            
            try App.boot(app)
            try app.asyncRun().wait()
            
            try deleteData()
        } catch {
            fatalError("Failed to launch Vapor server: \(error.localizedDescription)")
        }
    }
    
    override func tearDown() {
        try? deleteData()
        try? app.runningServer?.close().wait()
    }

    func deleteData() throws {
        _ = try? app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<Void> in
            return Player.query(on: conn).delete().map(to: Void.self) { result in
                return Mission.query(on: conn).delete()
            }
        }).wait()
        print("deleted data")
    }
    
    func testCreatePlayerInDBPerformance() throws {
        guard let app = app else {
            throw PlayerDBTestsHelpersError.appIsNil
        }
        
        print("Started measured test run.")
        _ = try? app.withPooledConnection(to: .sqlite, closure: { conn -> Future<[Player]> in
            var futures = [Future<Player>]()
            for i in 0 ..< 1000 {
                let playerFuture = Player.createUser(username: "testUser\(i)", on: conn).map(to: Player.self) { result in
                    switch result {
                    case .success(let player):
                        return player
                    case .failure(let error):
                        throw error
                    }
                }
                futures.append(playerFuture)
            }
            return futures.flatten(on: app)
        }).wait()
        print("Finished measured test run.")
    }
    
    func testGame() throws {
        var player = Player(username: "testPlayer")
        player.id = UUID()
        
        var mission = Mission(owningPlayerID: player.id!)
        mission.id = UUID()
        let component = mission.currentStage.components.first!
        player.ownsMissionID = mission.id
        
        // simulate until mission done (with a maximum of a million steps)
        let maxSteps = 100_000
        var steps = 0
        while mission.currentStage.currentlyBuildingComponent?.percentageCompleted ?? 0 < 100 && steps < maxSteps {
            player = player.updatePlayer()
            mission = mission.updateMission()
            
            if player.cash >= component.cost {
                let investment = try player.investInComponent(component, in: mission, date: Date())
                player = investment.changedPlayer
                mission = investment.changedMission
            }
            
            if player.technologyPoints >= player.costOfNextTechnologyLevel {
                player = try player.investInNextLevelOfTechnology()
            }
            
            steps += 1
        }
        print("Completed running simulation (max steps: \(maxSteps).")
        if mission.percentageDone >= 100 {
            print("Completed mission in \(steps) update steps.")
            XCTAssertTrue(true)
        } else {
            print("Failed to complete mission in \(maxSteps) steps.")
            XCTAssertTrue(true)
        }
        print("Player: \(player) \nMission: \(mission)")
    }
    
    // HELPERS
    enum PlayerDBTestsHelpersError: Error {
        case appIsNil
    }

    
    static let allTests = [
        ("testCreatePlayerInDBPerformance", testCreatePlayerInDBPerformance),
        ("testGame", testGame)
    ]
}

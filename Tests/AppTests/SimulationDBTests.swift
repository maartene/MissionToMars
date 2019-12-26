//
//  SimulationDBTests.swift
//  AppTests
//
//  Created by Maarten Engels on 15/12/2019.
//

import App
import Vapor
import Dispatch
import XCTest
@testable import Model

final class SimulationDBTests : XCTestCase {
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
            try setupData()
        } catch {
            fatalError("Failed to launch Vapor server: \(error.localizedDescription)")
        }
    }
    
    override func tearDown() {
        try? deleteData()
        try? app.runningServer?.close().wait()
    }

    func deleteData() throws {
        _ = try? app?.withPooledConnection(to: .psql, closure: { conn -> Future<Void> in
            return Player.query(on: conn).delete().map(to: Void.self) {
                return Mission.query(on: conn).delete().map(to: Void.self) {
                    return Simulation.query(on: conn).delete()
                }
            }
        }).wait()
        print("Deleted database entries.")
    }
    
    func testCreateSimulationInDatabase() throws {
        let simulation = try? app?.withPooledConnection(to: .psql, closure: { conn -> Future<[Simulation]> in
            return Simulation.query(on: conn).all()
        }).wait().first
        print(String(describing: simulation))
        XCTAssertNotNil(simulation)
    }
    
    func testUpdatePlayersUsingSimulationInDatabase() throws {
        let players = try app!.withPooledConnection(to: .psql, closure: { conn -> Future<[Player]> in
            Player.query(on: conn).all()
            }).wait()
        
        let loadedSimulations = try app!.withPooledConnection(to: .psql, closure: { conn -> Future<[Simulation]> in
            return Simulation.query(on: conn).all()
        }).wait()
        
        XCTAssertEqual(loadedSimulations.count, 1)
        let loadedSimulation = loadedSimulations.first!
        
        let result = loadedSimulation.updateSimulation(currentDate: Date(), players: players, missions: [])
        XCTAssertEqual(result.updatedSimulation.id, loadedSimulation.id, "UUID should be unchanged after update.")
        
        for i in 0 ..< players.count {
            XCTAssertGreaterThan(result.updatedPlayers[i].cash, players[i].cash)
            XCTAssertGreaterThan(result.updatedPlayers[i].technologyPoints, players[i].technologyPoints)
            XCTAssertEqual(result.updatedPlayers[i].id, players[i].id, "uuid for player \(i) should be the same after update.")
        }
    }
    
    func testSaveUpdatedPlayers() throws {
        let players = try app!.withPooledConnection(to: .psql, closure: { conn -> Future<[Player]> in
        Player.query(on: conn).all()
        }).wait()
        
        let updatedPlayers = players.map { player in
            player.updatePlayer()
        }
        
        _ = try app!.withPooledConnection(to: .psql, closure: { conn -> Future<[Player]> in
            return updatedPlayers.map { player in
                return player.save(on: conn)
            }.flatten(on: conn)
            }).wait()
                
        let updatedPlayersFromDB = try app!.withPooledConnection(to: .psql, closure: { conn -> Future<[Player]> in
        Player.query(on: conn).all()
        }).wait()
        
        for i in 0 ..< players.count {
            XCTAssertGreaterThan(updatedPlayersFromDB[i].cash, players[i].cash)
            XCTAssertGreaterThan(updatedPlayersFromDB[i].technologyPoints, players[i].technologyPoints)
        }
    }
    
    func testSaveUpdatedSimulation() throws {
        // load simulation
        let loadedSimulations = try app!.withPooledConnection(to: .psql) { conn in
            return Simulation.query(on: conn).all()
        }.wait()
        
        XCTAssertEqual(loadedSimulations.count, 1, "There should be only one simulation in the database.")
        
        let loadedSimulation = loadedSimulations.first!
        
        let result = loadedSimulation.updateSimulation(currentDate: Date(), players: [], missions: [])
        
        let savedSimulation = try app!.withPooledConnection(to: .psql) { conn in
            return result.updatedSimulation.update(on: conn)
        }.wait()
        
        XCTAssertEqual(loadedSimulation.id, savedSimulation.id, "Simulation id should not change after update/save.")
        XCTAssertGreaterThan(savedSimulation.tickCount, loadedSimulation.tickCount, "tickCount should increase")
        XCTAssertGreaterThan(savedSimulation.gameDate, loadedSimulation.gameDate, "time should pass.")
        XCTAssertGreaterThan(savedSimulation.nextUpdateDate, loadedSimulation.nextUpdateDate, "time should pass.")
    }
    
    func setupData() throws {
        _ = try? app?.withPooledConnection(to: .psql, closure: { conn -> Future<String> in
            var createPlayerFutures = [Future<Result<Player, Player.PlayerError>>]()
            for i in 0 ..< 100 {
                createPlayerFutures.append(Player.createUser(username: "testUser\(i)", on: conn))
            }
            
            let createPlayersFuture = createPlayerFutures.flatten(on: conn)
            
            return createPlayersFuture.flatMap(to: String.self) { result in
                let gameDate = Date().addingTimeInterval(24*60*60*365)
                let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
                return simulation.create(on: conn).map(to: String.self) { result in
                    return "Done creating users and simulation." }
            }
        }).wait()
    }
    
    static let allTests = [
        ("testSaveUpdatedPlayers", testSaveUpdatedPlayers),
        ("testUpdatePlayersUsingSimulationInDatabase", testUpdatePlayersUsingSimulationInDatabase),
        ("testCreateSimulationInDatabase", testCreateSimulationInDatabase),
        ("testSaveUpdatedSimulation", testSaveUpdatedSimulation)
    ]
}

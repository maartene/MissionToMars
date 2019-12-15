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
        _ = try? app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<Void> in
            return Player.query(on: conn).delete().map(to: Void.self) {
                return Mission.query(on: conn).delete().map(to: Void.self) {
                    return Simulation.query(on: conn).delete()
                }
            }
        }).wait()
        print("Deleted database entries.")
    }
    
    func testCreateSimulationInDatabase() throws {
        let simulation = try? app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<[Simulation]> in
            return Simulation.query(on: conn).all()
        }).wait().first
        print(String(describing: simulation))
        XCTAssertNotNil(simulation)
    }
    
    func testUpdatePlayersUsingSimulationInDatabase() throws {
        let players = try app!.withPooledConnection(to: .sqlite, closure: { conn -> Future<[Player]> in
            Player.query(on: conn).all()
            }).wait()
        
        let simulation = try app!.withPooledConnection(to: .sqlite, closure: { conn -> Future<[Simulation]> in
            return Simulation.query(on: conn).all()
        }).wait().first!
        
        var updatedPlayers = [Player]()
        _ = simulation.update(currentDate: Date()) {
            updatedPlayers = players.map { player in
                player.update()
            }
        }
        
        for i in 0 ..< players.count {
            XCTAssertGreaterThan(updatedPlayers[i].cash, players[i].cash)
            XCTAssertGreaterThan(updatedPlayers[i].technologyPoints, players[i].technologyPoints)
        }
    }
    
    func testSaveUpdatedPlayers() throws {
        let players = try app!.withPooledConnection(to: .sqlite, closure: { conn -> Future<[Player]> in
        Player.query(on: conn).all()
        }).wait()
        
        let updatedPlayers = players.map { player in
            player.update()
        }
        
        for player in updatedPlayers {
            _ = try app!.withPooledConnection(to: .sqlite, closure: { conn -> Future<Void> in
                player.update(on: conn)
                return Future.map(on: conn) {
                    return
                }
            }).wait()
        }
                
        let updatedPlayersFromDB = try app!.withPooledConnection(to: .sqlite, closure: { conn -> Future<[Player]> in
        Player.query(on: conn).all()
        }).wait()
        
        for i in 0 ..< players.count {
            XCTAssertGreaterThan(updatedPlayersFromDB[i].cash, players[i].cash)
            XCTAssertGreaterThan(updatedPlayersFromDB[i].technologyPoints, players[i].technologyPoints)
        }
    }
    
    func setupData() throws {
        _ = try? app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<Void> in
            for i in 0 ..< 100 {
                _ = Player.createUser(username: "testUser\(i)", on: conn)
            }
            
            let gameDate = Date().addingTimeInterval(24*60*60*365)
            let simulation = Simulation(tickCount: 0, gameDate: gameDate, nextUpdateDate: Date())
            _ = simulation.create(on: conn)
            
            return Future.map(on: conn) { return }
        }).wait()
    }
    
    static let allTests = [
        ("testSaveUpdatedPlayers", testSaveUpdatedPlayers),
        ("testUpdatePlayersUsingSimulationInDatabase", testUpdatePlayersUsingSimulationInDatabase),
        ("testCreateSimulationInDatabase", testCreateSimulationInDatabase)
    ]
}

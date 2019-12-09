//
//  PlayerDBTests.swift
//  AppTests
//
//  Created by Maarten Engels on 09/12/2019.
//

import Vapor
import App
import Dispatch
import XCTest
@testable import Model

final class PlayerDBTests : XCTestCase {
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
        } catch {
            fatalError("Failed to launch Vapor server: \(error.localizedDescription)")
        }
    }
    
    override func tearDown() {
        _ = try? app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<Void> in
            _ = Player.query(on: conn).delete()
            _ = Mission.query(on: conn).delete()
            print("Deleted database entries.")
            return Future.map(on: conn) { return }
        }).wait()
        try? app.runningServer?.close().wait()
    }

    func testCannotCreatePlayerWithExistingUsername() throws {
        _ = try createTestPlayer().wait()
        XCTAssertThrowsError(try createTestPlayer().wait())
    }
    
    func testCreatePlayer() throws {
        let player = try createTestPlayer().wait()
        
        print(player)
        XCTAssertNotNil(player.id, " uuid")
    }
    
    func testCreateMission() throws {
        let mission = try createTestMission(for: UUID()).wait()
        
        XCTAssertNotNil(mission, " mission should not be nil")
        print(mission)
        XCTAssertNotNil(mission.id, " uuid")
    }
    
    func testAddMissionToPlayer() throws {
        let result = try createTestPlayerWithMission()
        
        print(result.savedPlayer)
        print(result.savedMission)
        XCTAssertEqual(result.savedPlayer.ownsMissionID, result.savedMission.id)
        XCTAssertEqual(result.savedMission.owningPlayerID, result.savedPlayer.id)
    }
    
    func testInvestInMission() throws {
        let playerMissionCombo = try createTestPlayerWithMission()
        
        let result = try app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<(changedPlayer: Player, changedMission: Mission)> in
            return try playerMissionCombo.savedPlayer.investInMission(amount: playerMissionCombo.savedPlayer.cash - 1, on: conn)
            }).wait()
        
        XCTAssertNotNil(result, " result should not be nil.")
        
        XCTAssertLessThan(result!.changedPlayer.cash, playerMissionCombo.savedPlayer.cash, " cash")
        XCTAssertGreaterThan(result!.changedMission.percentageDone, playerMissionCombo.savedMission.percentageDone, " % done")
    }
    
    func testInvestInTechnology() throws {
        let player = try createTestPlayer().wait()
        let changedPlayer = try player.investInNextLevelOfTechnology()
        let savedPlayer = try app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<Player> in
            return changedPlayer.save(on: conn)
        }).wait()
        
        XCTAssertNotNil(savedPlayer, " savedPlayer should not be nil")
        
        XCTAssertLessThan(savedPlayer!.technologyPoints, player.technologyPoints, " technology points")
        XCTAssertGreaterThan(savedPlayer!.technologyLevel, player.technologyLevel, " tech levels")
        
        XCTAssertEqual(savedPlayer!.technologyPoints, changedPlayer.technologyPoints, " technology points")
        XCTAssertEqual(savedPlayer!.technologyLevel, changedPlayer.technologyLevel, " tech levels")
    }
    
    func testDonateCashToPlayer() throws {
        var player1 = try createTestPlayer(username: "player1").wait()
        let player2 = try createTestPlayer(username: "player2").wait()
        
        player1.supportsPlayerID = player2.id
        
        let result = try app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<(donatingPlayer: Player, receivingPlayer: Player)> in
            return try player1.donateToSupportedPlayer(cash: player1.cash - 1, on: conn)
        }).wait()
        
        XCTAssertNotNil(result, " result should not be nil")
        XCTAssertGreaterThan(result!.receivingPlayer.cash, player2.cash, " cash")
        XCTAssertLessThan(result!.donatingPlayer.cash, player1.cash, " cash")
    }
    
    func testDonateTechToPlayer() throws {
        var player1 = try createTestPlayer(username: "player1").wait()
        let player2 = try createTestPlayer(username: "player2").wait()
        
        player1.supportsPlayerID = player2.id
        
        let result = try app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<(donatingPlayer: Player, receivingPlayer: Player)> in
            return try player1.donateToSupportedPlayer(techPoints: player1.technologyPoints - 1, on: conn)
        }).wait()
        
        XCTAssertNotNil(result, " result should not be nil")
        XCTAssertGreaterThan(result!.receivingPlayer.technologyPoints, player2.technologyPoints, " technologyPoints")
        XCTAssertLessThan(result!.donatingPlayer.technologyPoints, player1.technologyPoints, " technologyPoints")
    }
    
    // HELPERS
    enum PlayerDBTestsHelpersError: Error {
        case appIsNil
    }
    
    func createTestPlayer(username: String = "testUser") throws -> Future<Player> {
        guard let app = app else {
            throw PlayerDBTestsHelpersError.appIsNil
        }
        
        return app.withPooledConnection(to: .sqlite, closure: { conn -> Future<Player> in
            return try Player.createUser(username: username, on: conn)
        })
    }
    
    func createTestMission(for owningPlayerID: UUID) throws -> Future<Mission> {
        guard let app = app else {
            throw PlayerDBTestsHelpersError.appIsNil
        }
        
        return app.withPooledConnection(to: .sqlite, closure: { conn -> Future<Mission> in
            return Mission(owningPlayerID: owningPlayerID).create(on: conn)
        })
    }
    
    func createTestPlayerWithMission() throws -> (savedPlayer: Player, savedMission: Mission) {
        guard let app = app else {
            throw PlayerDBTestsHelpersError.appIsNil
        }
        
        var player = try createTestPlayer().wait()
        let mission = try createTestMission(for: player.id!).wait()
        
        player.ownsMissionID = mission.id
        let savedPlayer = try app.withPooledConnection(to: .sqlite, closure: { conn -> Future<Player> in
            return player.save(on: conn)
        }).wait()
        
        return (savedPlayer, mission)
    }
    
    static let allTests = [
        ("testCreatePlayer", testCreatePlayer),
        ("testCannotCreatePlayerWithExistingUsername", testCannotCreatePlayerWithExistingUsername),
        ("testAddMissionToPlayer", testAddMissionToPlayer),
        ("testInvestInMission", testInvestInMission),
        ("testInvestInTechnology", testInvestInTechnology),
        ("testDonateCashToPlayer", testDonateCashToPlayer),
        ("testDonateTechToPlayer", testDonateTechToPlayer),
    ]
}

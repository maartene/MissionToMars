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
    
    
    func testCannotCreatePlayerWithExistingUsername() throws {
        _ = try createTestPlayer()
        XCTAssertThrowsError(try createTestPlayer())
    }
    
    func testCreatePlayer() throws {
        let player = try createTestPlayer()
        
        //print(player)
        XCTAssertNotNil(player.id, " uuid")
    }
    
    func testSaveUpdatedPlayer() throws {
        let player = try createTestPlayer()
        let updatedPlayer = player.updatePlayer()
        let savedPlayer = try app!.withPooledConnection(to: .sqlite) { conn -> Future<Player> in
            return updatedPlayer.save(on: conn)
        }.wait()
        
        XCTAssertNotNil(savedPlayer.id, " uuid")
        XCTAssertEqual(savedPlayer.id, player.id, " uuids should be the same after saving.")
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
    
    func testInvestInTechnology() throws {
        let player = try createTestPlayer()
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
        var player1 = try createTestPlayer(username: "player1")
        let player2 = try createTestPlayer(username: "player2")
        
        player1.supportsPlayerID = player2.id
        
        let result = try app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<Result<(donatingPlayer: Player, receivingPlayer: Player), Error>> in
            return try player1.donateToSupportedPlayer(cash: player1.cash - 1, on: conn)
        }).wait()
        
        XCTAssertNotNil(result, " result should not be nil")
        switch result! {
        case .failure(let error):
            XCTFail("Received a failure from test \(error)")
        case .success(let donationResult):
            XCTAssertGreaterThan(donationResult.receivingPlayer.cash, player2.cash, " cash")
            XCTAssertLessThan(donationResult.donatingPlayer.cash, player1.cash, " cash")
        }
    }
    
    func testDonateTechToPlayer() throws {
        var player1 = try createTestPlayer(username: "player1")
        let player2 = try createTestPlayer(username: "player2")
        
        player1.supportsPlayerID = player2.id
        
        let result = try app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<Result<(donatingPlayer: Player, receivingPlayer: Player), Error>> in
            return try player1.donateToSupportedPlayer(techPoints: player1.technologyPoints - 1, on: conn)
        }).wait()
        
        XCTAssertNotNil(result, " result should not be nil")
        switch result! {
        case .failure(let error):
            XCTFail("Received a failure from test \(error)")
        case .success(let donationResult):
            XCTAssertGreaterThan(donationResult.receivingPlayer.technologyPoints, player2.technologyPoints, " technologyPoints")
            XCTAssertLessThan(donationResult.donatingPlayer.technologyPoints, player1.technologyPoints, " technologyPoints")
        }
    }
    
    func testBuildComponent() throws {
        let playerMissionCombo = try createTestPlayerWithMission()
        let player = playerMissionCombo.savedPlayer
        let mission = playerMissionCombo.savedMission
        
        XCTAssertGreaterThan(mission.currentStage.components.count, 1)
        let component = mission.currentStage.components[1]
        
        XCTAssertGreaterThanOrEqual(player.cash, component.cost, "cash")
        
        let result = try app?.withPooledConnection(to: .sqlite) { conn -> Future<Result<(changedPlayer: Player, changedMission: Mission), Player.PlayerError>> in
            return try player.investInComponent(component, on: conn, date: Date())
        }.wait()
        
        XCTAssertNotNil(result, "result should not be nil")
        switch result! {
        case .failure(let error):
            XCTFail("Received a failure from test \(error)")
        case .success(let buildResult):
            XCTAssertNotNil(buildResult.changedMission.currentStage.currentlyBuildingComponent, "Should now be building something.")
            XCTAssertLessThan(buildResult.changedPlayer.cash, player.cash, "cash")
        }
        
    }
    
    
    // HELPERS
    enum PlayerDBTestsHelpersError: Error {
        case appIsNil
    }
    
    func createTestPlayer(username: String = "testUser") throws -> Player {
        guard let app = app else {
            throw PlayerDBTestsHelpersError.appIsNil
        }
        
        return try app.withPooledConnection(to: .sqlite, closure: { conn -> Future<Result<Player, Player.PlayerError>> in
            return Player.createUser(username: username, on: conn)
            }).map(to: Player.self) { result in
                switch result {
                case .success(let player):
                    return player
                case .failure(let error):
                    throw error
                }
        }.wait()
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
        
        var player = try createTestPlayer()
        let mission = try createTestMission(for: player.id!).wait()
        
        player.debug_setCash(mission.currentStage.unstartedComponents[0].cost)
        
        player.ownsMissionID = mission.id
        let savedPlayer = try app.withPooledConnection(to: .sqlite, closure: { conn -> Future<Player> in
            return player.save(on: conn)
        }).wait()
        
        return (savedPlayer, mission)
    }
    
    static let allTests = [
        ("testCreatePlayer", testCreatePlayer),
        ("testCreateMission", testCreateMission),
        ("testCannotCreatePlayerWithExistingUsername", testCannotCreatePlayerWithExistingUsername),
        ("testAddMissionToPlayer", testAddMissionToPlayer),
        ("testInvestInTechnology", testInvestInTechnology),
        ("testDonateCashToPlayer", testDonateCashToPlayer),
        ("testDonateTechToPlayer", testDonateTechToPlayer),
        ("testSaveUpdatedPlayer", testSaveUpdatedPlayer),
        ("testBuildComponent", testBuildComponent)
    ]
}

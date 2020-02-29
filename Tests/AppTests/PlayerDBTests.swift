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

/*final class PlayerDBTests : XCTestCase {
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
    
    func testDonateCashToPlayer() throws {
        let playerAndMission = try createTestPlayerWithMission()
        let player1 = playerAndMission.savedPlayer
        var player2 = try createTestPlayer(emailAddress: "player2@example.com")
        
        let mission = playerAndMission.savedMission
        player2.supportsPlayerID = player1.id
        
        player2 = try app!.withPooledConnection(to: .sqlite, closure: { conn -> Future<Player> in
            return player2.save(on: conn)
        }).wait()
        
        let supportingPlayers = try app!.withPooledConnection(to: .sqlite, closure: { conn -> Future<[Player]> in
            return try mission.getSupportingPlayers(on: conn)
        }).wait()
        
        XCTAssert(supportingPlayers.contains(where: {player in player.id == player1.id}))
        XCTAssert(supportingPlayers.contains(where: {player in player.id == player2.id}))
        
        let result = try app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<Result<(donatingPlayer: Player, receivingPlayer: Player), Error>> in
            return try player1.donateToPlayerSupportingSameMission(cash: player1.cash - 1.0, receivingPlayer: player2, on: conn)
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
        let playerAndMission = try createTestPlayerWithMission()
        let player1 = playerAndMission.savedPlayer
        var player2 = try createTestPlayer(emailAddress: "player2@example.com")
        
        let mission = playerAndMission.savedMission
        player2.supportsPlayerID = player1.id
        
        player2 = try app!.withPooledConnection(to: .sqlite, closure: { conn -> Future<Player> in
            return player2.save(on: conn)
        }).wait()
        
        let supportingPlayers = try app!.withPooledConnection(to: .sqlite, closure: { conn -> Future<[Player]> in
            return try mission.getSupportingPlayers(on: conn)
        }).wait()
        
        XCTAssert(supportingPlayers.contains(where: {player in player.id == player1.id}))
        XCTAssert(supportingPlayers.contains(where: {player in player.id == player2.id}))
        
        let result = try app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<Result<(donatingPlayer: Player, receivingPlayer: Player), Error>> in
            return try player1.donateToPlayerSupportingSameMission(tech: player1.technologyPoints - 1.0, receivingPlayer: player2, on: conn)
        }).wait()
        
        XCTAssertNotNil(result, " result should not be nil")
        switch result! {
        case .failure(let error):
            XCTFail("Received a failure from test \(error)")
        case .success(let donationResult):
            XCTAssertGreaterThan(donationResult.receivingPlayer.technologyPoints, player2.technologyPoints, " techPoints")
            XCTAssertLessThan(donationResult.donatingPlayer.technologyPoints, player1.technologyPoints, " techPoints")
        }
    }
    
    func testCannotDonateToPlayerNotSupportingSameMission() throws {
        let playerAndMission = try createTestPlayerWithMission()
        let player1 = playerAndMission.savedPlayer
        let player2 = try createTestPlayer(emailAddress: "player2@example.com")
        
        let mission = playerAndMission.savedMission
            
        let supportingPlayers = try app!.withPooledConnection(to: .sqlite, closure: { conn -> Future<[Player]> in
            return try mission.getSupportingPlayers(on: conn)
        }).wait()
        
        XCTAssert(supportingPlayers.contains(where: {player in player.id == player1.id}))
        XCTAssert(supportingPlayers.contains(where: {player in player.id == player2.id}) == false)
        
        let result = try app?.withPooledConnection(to: .sqlite, closure: { conn -> Future<Result<(donatingPlayer: Player, receivingPlayer: Player), Error>> in
            return try player1.donateToPlayerSupportingSameMission(tech: player1.technologyPoints - 1.0, receivingPlayer: player2, on: conn)
        }).wait()
        
        XCTAssertNotNil(result, " result should not be nil")
        switch result! {
        case .failure(let error):
            print(error)
        case .success:
            XCTFail("Donation should not succeed.")
        }
    }
    
    func testBuildComponent() throws {
        let playerMissionCombo = try createTestPlayerWithMission()
        let player = playerMissionCombo.savedPlayer
        let mission = playerMissionCombo.savedMission
        
        XCTAssertGreaterThan(mission.currentStage.components.count, 1)
        let component = mission.currentStage.components[1]
        
        XCTAssertGreaterThanOrEqual(player.cash, component.cost, "cash")
        
        let result = try app?.withPooledConnection(to: .sqlite) { conn -> Future<Result<(changedPlayer: Player, changedMission: Mission), Error>> in
            return try player.investInComponent(component, on: conn, date: Date())
        }.wait()
        
        XCTAssertNotNil(result, "result should not be nil")
        switch result! {
        case .failure(let error):
            XCTFail("Received a failure from test \(error)")
        case .success(let buildResult):
            XCTAssertGreaterThan(buildResult.changedMission.currentStage.currentlyBuildingComponents.count, 0, "Should now be building something.")
            XCTAssertLessThan(buildResult.changedPlayer.cash, player.cash, "cash")
        }
        
    }
    
    
    // HELPERS
    enum PlayerDBTestsHelpersError: Error {
        case appIsNil
    }
    
    func createTestPlayer(emailAddress: String = "example@example.com") throws -> Player {
        guard let app = app else {
            throw PlayerDBTestsHelpersError.appIsNil
        }
        
        return try app.withPooledConnection(to: .sqlite, closure: { conn -> Future<Result<Player, Player.PlayerError>> in
            return Player.createUser(emailAddress: emailAddress, name: "testUser", on: conn)
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
        ("testDonateCashToPlayer", testDonateCashToPlayer),
        ("testDonateTechToPlayer", testDonateTechToPlayer),
        ("testSaveUpdatedPlayer", testSaveUpdatedPlayer),
        ("testBuildComponent", testBuildComponent),
        ("testCannotDonateToPlayerNotSupportingSameMission", testCannotDonateToPlayerNotSupportingSameMission)
    ]
}
*/

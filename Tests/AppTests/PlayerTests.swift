//
//  PlayerTests.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

@testable import App
import Dispatch
import XCTest

final class PlayerTests : XCTestCase {

    func testUpdatePlayer() throws {
        let player = Player(emailAddress: "example@example.com", name: "testUser", password: "")
        
        let updatedPlayer = player.updatePlayer()
        
        XCTAssertGreaterThan(updatedPlayer.cash, player.cash, " cash")
        XCTAssertGreaterThan(updatedPlayer.technologyPoints, player.technologyPoints, " cash")
        XCTAssertEqual(updatedPlayer.id, player.id, " UUID should be the same")
    }

    func testDonateCashToPlayer() throws {
        let givingPlayer = Player(emailAddress: "example@example.com", name: "giving player", password: "")
        let receivingPlayer = Player(emailAddress: "example2@example.com", name: "receiving player", password: "")
        
        let updatedPlayers = try givingPlayer.donate(cash: 100, to: receivingPlayer)
        
        XCTAssertGreaterThan(updatedPlayers.receivingPlayer.cash, receivingPlayer.cash, " cash")
        XCTAssertLessThan(updatedPlayers.donatingPlayer.cash, givingPlayer.cash, " cash")
    }
    
    func testCreatePlayerWithStartingImprovement() throws {
        let improvement = Improvement.getImprovementByName(.InvestmentBank)!
        
        let player = Player(emailAddress: "example@example.com", name: "Example User", password: "", startImprovementShortName: improvement.shortName)
        
        XCTAssert(player.completedImprovements.contains(improvement), "Player should have a completed \(improvement.name)")
        
        let techConsultancy = Improvement.getImprovementByName(.TechConsultancy)!
        XCTAssert(player.improvements.contains(techConsultancy) == false, "Player should not have a tech consultancy.")
    }

    func testDonateTechnologyToPlayer() throws {
        let givingPlayer = Player(emailAddress: "example@example.com", name: "giving player", password: "")
        let receivingPlayer = Player(emailAddress: "example2@example.com", name: "receiving player", password: "")
        
        let updatedPlayers = try givingPlayer.donate(techPoints: 10, to: receivingPlayer)
        
        XCTAssertGreaterThan(updatedPlayers.receivingPlayer.technologyPoints, receivingPlayer.technologyPoints, " tech points")
        XCTAssertLessThan(updatedPlayers.donatingPlayer.technologyPoints, givingPlayer.technologyPoints, " tech points")
    }
    
    func testCannotDonateMoreCashThanAvailable() throws {
        let givingPlayer = Player(emailAddress: "example@example.com", name: "giving player", password: "")
        let receivingPlayer = Player(emailAddress: "example2@example.com", name: "receiving player", password: "")
        
        XCTAssertThrowsError(try givingPlayer.donate(cash: givingPlayer.cash + 1, to: receivingPlayer))
    }
    
    func testCannotDonateMoreTechThanAvailable() throws {
        let givingPlayer = Player(emailAddress: "example@example.com", name: "giving player", password: "")
        let receivingPlayer = Player(emailAddress: "example2@example.com", name: "receiving player", password: "")
        
        XCTAssertThrowsError(try givingPlayer.donate(techPoints: givingPlayer.technologyPoints + 1, to: receivingPlayer))
    }
    
    func testUpdatePlayerWithoutImprovementsShouldNotChangePlayer() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser", password: "")
        player = try player.removeImprovementInSlot(0)
        let updatedPlayer = player.updatePlayer()
        XCTAssertEqual(player.cash, updatedPlayer.cash)
        XCTAssertEqual(player.technologyPoints, updatedPlayer.technologyPoints)
    }
    
    func testPlayerCannotDonateToSelf() throws {
        let player = Player(emailAddress: "example@example.com", name: "testUser", password: "")
        XCTAssertThrowsError(try player.donate(cash: player.cash - 1.0, to: player))
        XCTAssertThrowsError(try player.donate(techPoints: player.technologyPoints - 1.0, to: player))
    }
    
    /*func testUpdateIncreasesActionPoints() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser", password: "")
        player.debug_setActionPoints(0)
        XCTAssertLessThan(player.actionPoints, MAXIMUM_PLAYER_ACTION_POINTS)
        
        let updatedPlayer = player.updatePlayer()
        
        XCTAssertGreaterThan(updatedPlayer.actionPoints, player.actionPoints)
    }
    
    func testUpdateDoesNotIncreaseActionPointsWhenAtMaximum() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser", password: "")
        player.debug_setActionPoints(MAXIMUM_PLAYER_ACTION_POINTS)
        XCTAssertEqual(player.actionPoints, MAXIMUM_PLAYER_ACTION_POINTS)
        
        let updatedPlayer = player.updatePlayer()
        
        XCTAssertEqual(updatedPlayer.actionPoints, player.actionPoints)
    }*/
    
    static let allTests = [
        ("testUpdatePlayer", testUpdatePlayer),
        ("testDonateCashToPlayer", testDonateCashToPlayer),
        ("testDonateTechnologyToPlayer", testDonateTechnologyToPlayer),
        ("testCannotDonateMoreCashThanAvailable", testCannotDonateMoreCashThanAvailable),
        ("testCannotDonateMoreTechThanAvailable", testCannotDonateMoreTechThanAvailable),
        ("testUpdatePlayerWithoutImprovementsShouldNotChangePlayer", testUpdatePlayerWithoutImprovementsShouldNotChangePlayer),
        ("testPlayerCannotDonateToSelf", testPlayerCannotDonateToSelf),
        //("testUpdateIncreasesActionPoints", testUpdateIncreasesActionPoints),
        //("testUpdateDoesNotIncreaseActionPointsWhenAtMaximum", testUpdateDoesNotIncreaseActionPointsWhenAtMaximum),
    ]
}

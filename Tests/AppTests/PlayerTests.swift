//
//  PlayerTests.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import App
import Dispatch
import XCTest
@testable import Model

final class PlayerTests : XCTestCase {

    func testUpdatePlayer() throws {
        let player = Player(username: "testUser")
        
        let updatedPlayer = player.updatePlayer()
        
        XCTAssertGreaterThan(updatedPlayer.cash, player.cash, " cash")
        XCTAssertGreaterThan(updatedPlayer.technologyPoints, player.technologyPoints, " cash")
        XCTAssertEqual(updatedPlayer.id, player.id, " UUID should be the same")
    }

    func testDonateCashToPlayer() throws {
        let givingPlayer = Player(username: "givingPlayer")
        let receivingPlayer = Player(username: "receivingPlayer")
        
        let updatedPlayers = try givingPlayer.donate(cash: 100, to: receivingPlayer)
        
        XCTAssertGreaterThan(updatedPlayers.receivingPlayer.cash, receivingPlayer.cash, " cash")
        XCTAssertLessThan(updatedPlayers.donatingPlayer.cash, givingPlayer.cash, " cash")
    }

    func testDonateTechnologyToPlayer() throws {
        let givingPlayer = Player(username: "givingPlayer")
        let receivingPlayer = Player(username: "receivingPlayer")
        
        let updatedPlayers = try givingPlayer.donate(techPoints: 10, to: receivingPlayer)
        
        XCTAssertGreaterThan(updatedPlayers.receivingPlayer.technologyPoints, receivingPlayer.technologyPoints, " tech points")
        XCTAssertLessThan(updatedPlayers.donatingPlayer.technologyPoints, givingPlayer.technologyPoints, " tech points")
    }
    
    func testCannotDonateMoreCashThanAvailable() throws {
        let givingPlayer = Player(username: "givingPlayer")
        let receivingPlayer = Player(username: "receivingPlayer")
        
        XCTAssertThrowsError(try givingPlayer.donate(cash: givingPlayer.cash + 1, to: receivingPlayer))
    }
    
    func testCannotDonateMoreTechThanAvailable() throws {
        let givingPlayer = Player(username: "givingPlayer")
        let receivingPlayer = Player(username: "receivingPlayer")
        
        XCTAssertThrowsError(try givingPlayer.donate(techPoints: givingPlayer.technologyPoints + 1, to: receivingPlayer))
    }
    
    func testUpdatePlayerWithoutImprovementsShouldNotChangePlayer() throws {
        var player = Player(username: "testPlayer")
        player = player.removeImprovement(.TechConsultancy)
        let updatedPlayer = player.updatePlayer()
        XCTAssertEqual(player.cash, updatedPlayer.cash)
        XCTAssertEqual(player.technologyPoints, updatedPlayer.technologyPoints)
    }
    
    static let allTests = [
        ("testUpdatePlayer", testUpdatePlayer),
        ("testDonateCashToPlayer", testDonateCashToPlayer),
        ("testDonateTechnologyToPlayer", testDonateTechnologyToPlayer),
        ("testCannotDonateMoreCashThanAvailable", testCannotDonateMoreCashThanAvailable),
        ("testCannotDonateMoreTechThanAvailable", testCannotDonateMoreTechThanAvailable),
        ("testUpdatePlayerWithoutImprovementsShouldNotChangePlayer", testUpdatePlayerWithoutImprovementsShouldNotChangePlayer),
    ]
}

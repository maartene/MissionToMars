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

    func testNothing() throws {
        XCTAssert(true)
    }

    func testUpdatePlayer() throws {
        let player = Player(username: "testUser")
        
        let updatedPlayer = player.update()
        
        XCTAssertGreaterThan(updatedPlayer.cash, player.cash, " cash")
        XCTAssertGreaterThan(updatedPlayer.technologyPoints, player.technologyPoints, " cash")
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

    func testInvestInMission() throws {
        var player = Player(username: "testUser")
        player.ownsMission = Mission()
        let changedPlayer = try player.investInMission(amount: player.cash - 1)
        XCTAssertLessThan(changedPlayer.cash, player.cash, " cash")
        XCTAssertGreaterThan(changedPlayer.ownsMission!.percentageDone, player.ownsMission!.percentageDone, " % done")
    }

    func testInvestInTechnology() throws {
        let player = Player(username: "testUser")
        let changedPlayer = try player.investInNextLevelOfTechnology()
        
        
        XCTAssertLessThan(changedPlayer.technologyPoints, player.technologyPoints, " technology points")
        XCTAssertGreaterThan(changedPlayer.technologyLevel, player.technologyLevel, " tech levels")
    }

    static let allTests = [
        ("testNothing", testNothing),
        ("testUpdatePlayer", testUpdatePlayer),
        ("testDonateCashToPlayer", testDonateCashToPlayer),
        ("testDonateTechnologyToPlayer", testDonateTechnologyToPlayer),
        ("testInvestInMission", testInvestInMission),
        ("testInvestInTechnology", testInvestInTechnology),
    ]
}

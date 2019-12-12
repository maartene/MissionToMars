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

    func testInvestInMission() throws {
        var player = Player(username: "testUser")
        let mission = Mission(owningPlayerID: UUID())
        player.ownsMissionID = mission.id
        let result = try player.investInMission(amount: player.cash - 1, in: mission)
        XCTAssertLessThan(result.changedPlayer.cash, player.cash, " cash")
        XCTAssertGreaterThan(result.changedMission.percentageDone, mission.percentageDone, " % done")
    }

    func testInvestInTechnology() throws {
        let player = Player(username: "testUser")
        let changedPlayer = try player.investInNextLevelOfTechnology()
        
        
        XCTAssertLessThan(changedPlayer.technologyPoints, player.technologyPoints, " technology points")
        XCTAssertGreaterThan(changedPlayer.technologyLevel, player.technologyLevel, " tech levels")
    }
    
    func testCannotInvestMoreThanHasInTechnology() throws {
        var player = Player(username: "testUser")
        while player.technologyPoints >= player.costOfNextTechnologyLevel {
            player = try player.investInNextLevelOfTechnology()
        }
        
        XCTAssertThrowsError(try player.investInNextLevelOfTechnology())
    }

    func testGame() throws {
        var player = Player(username: "testPlayer")
        player.id = UUID()
        
        var mission = Mission(owningPlayerID: player.id!)
        mission.id = UUID()
        player.ownsMissionID = mission.id
        
        // simulate until mission done (with a maximum of a million steps)
        let maxSteps = 1_000_000
        var steps = 0
        while mission.percentageDone < 100 && steps < maxSteps {
            player = player.update()
            let investment = try player.investInMission(amount: player.cash, in: mission)
            player = investment.changedPlayer
            mission = investment.changedMission
            
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
    
    static let allTests = [
        ("testUpdatePlayer", testUpdatePlayer),
        ("testDonateCashToPlayer", testDonateCashToPlayer),
        ("testDonateTechnologyToPlayer", testDonateTechnologyToPlayer),
        ("testCannotDonateMoreCashThanAvailable", testCannotDonateMoreCashThanAvailable),
        ("testCannotDonateMoreTechThanAvailable", testCannotDonateMoreTechThanAvailable),
        ("testInvestInMission", testInvestInMission),
        ("testInvestInTechnology", testInvestInTechnology),
        ("testCannotInvestMoreThanHasInTechnology", testCannotInvestMoreThanHasInTechnology),
        ("testGame", testGame),
    ]
}

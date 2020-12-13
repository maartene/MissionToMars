//
//  EffectsTests.swift
//  AppTests
//
//  Created by Maarten Engels on 31/12/2019.
//

@testable import App
import Dispatch
import XCTest

class EffectsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExtraSlotTests() throws {
        var player = Player(emailAddress: "example@example.org", name: "exampleUser", password: "")
        
        let technology = Technology.getTechnologyByName(.PackageOptimization)!
        
        player = player.extraTech(amount: technology.cost)
        let updatedPlayer = try player.investInTechnology(technology)
        
        XCTAssertGreaterThan(updatedPlayer.improvementSlotsCount, player.improvementSlotsCount)
        
    }
    
    func testExtraRushTest() throws {
        var player = Player(emailAddress: "example@example.org", name: "exampleUser", password: "")
        
        let improvement = Improvement.getImprovementByName(.HostileTakeover)!
        player = player.extraIncome(amount: improvement.cost)
        
        let rushesBefore = player.rushes
        
        player = try player.startBuildImprovement(improvement, startDate: Date(), options: [.ignoreTechPrereqs])
        
        for _ in 0 ..< improvement.buildTime + 1{
            player = player.updatePlayer()
        }
        
        XCTAssertTrue(player.completedImprovements.contains(improvement))
        
        player = player.updatePlayer()
    
        XCTAssertGreaterThan(player.rushes, rushesBefore, "rushes")
        XCTAssertFalse(player.completedImprovements.contains(improvement))
    }
    
    /*func testExtraMaxActions() throws {
        var player = Player(emailAddress: "example@example.org", name: "exampleUser", password: "")
        var updatedPlayer = player
        
        var playerCount = 0
        while (player.actionPoints < player.maxActionPoints) {
            player = player.updatePlayer()
            playerCount += 1
        }
        
        updatedPlayer.forceUnlockTechnology(shortName: .ScaledAgileLeadership)
        
        var updatedPlayerCount = 0
        while (updatedPlayer.actionPoints < updatedPlayer.maxActionPoints) {
            updatedPlayer = updatedPlayer.updatePlayer()
            updatedPlayerCount += 1
        }
        
        XCTAssertGreaterThan(updatedPlayer.maxActionPoints, player.maxActionPoints)
        XCTAssertGreaterThan(updatedPlayer.actionPoints, player.actionPoints)
    }*/
    
    static let allTests = [
        ("testExtraSlotTests", testExtraSlotTests),
       // ("testExtraMaxActions", testExtraMaxActions),
        ("testExtraRushTest", testExtraRushTest)
    ]
}

//
//  ImprovementTests.swift
//  AppTests
//
//  Created by Maarten Engels on 22/12/2019.
//

import Foundation

import App
import Dispatch
import XCTest
@testable import Model

final class ImprovementTests : XCTestCase {
    func testStartBuildImprovement() throws {
        let improvement = Improvement(shortName: .Factory, name: "Factory", description: "Test", cost: 200, buildTime: 100)
        XCTAssertNil(improvement.buildStartedOn)
        let buildingComponent = try improvement.startBuild(startDate: Date())
        XCTAssertNotNil(buildingComponent.buildStartedOn)
    }
    
    func testGetImprovementByName() throws {
        for shortName in Improvement.ShortName.allCases {
            XCTAssertNotNil(Improvement.getImprovementByName(shortName), "There should be an improvement for every shortName value. Even for \(shortName)")
        }
    }
    
    func testUpdateShouldNotAdvancePercentageComplete() throws {
        guard let improvement = Improvement.getImprovementByName(.Factory) else {
            XCTFail("Improvement should not be nil.")
            return
        }
        XCTAssertEqual(improvement.percentageCompleted, 0, "Component should not have any percentage completion.")
        
        let updatedImprovement = improvement.updateImprovement()
        
        XCTAssertEqual(updatedImprovement.percentageCompleted, improvement.percentageCompleted, "The improvement should not be advanced if build has not yet started.")
        
    }
    
    func testImprovementShouldComplete() throws {
        guard let improvement = Improvement.getImprovementByName(.Factory) else {
            XCTFail("Improvement should not be nil.")
            return
        }
        
        let numberOfTicksRequired = improvement.buildTime
        let buildStartedImprovement = try improvement.startBuild(startDate: Date())
        let updatedImprovement = buildStartedImprovement.updateImprovement(ticks: numberOfTicksRequired)
        
        XCTAssertGreaterThanOrEqual(updatedImprovement.percentageCompleted, 100.0, "Improvement should be done by now.")
    }
    
    func testFactoryShouldIncreaseIncome() throws {
        guard let improvement = Improvement.getImprovementByName(.Factory) else {
            XCTFail("Improvement should not be nil.")
            return
        }
        
        let completedImprovement = try completeImprovement(improvement)
        
        let player = Player(username: "testUser")
        
        let updatedPlayer = completedImprovement.applyEffectForOwner(player: player)
        
        XCTAssertGreaterThan(updatedPlayer.cash, player.cash, " cash")
    }

    func completeImprovement(_ improvement: Improvement) throws -> Improvement {
        let startBuildImprovement = try improvement.startBuild(startDate: Date())
        let completedImprovement = startBuildImprovement.updateImprovement(ticks: improvement.buildTime)
        
        assert(completedImprovement.isCompleted, "Improvement should be completed.")
        
        return completedImprovement
    }
    
    static let allTests = [
        ("testStartBuildImprovement", testStartBuildImprovement),
        ("testGetImprovementByName", testGetImprovementByName),
        ("testUpdateShouldNotAdvancePercentageComplete", testUpdateShouldNotAdvancePercentageComplete),
        ("testImprovementShouldComplete", testImprovementShouldComplete),
    ]

}

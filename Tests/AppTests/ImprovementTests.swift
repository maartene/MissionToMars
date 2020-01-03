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
        let improvement = Improvement(shortName: .Faculty, name: "Factory", description: "Test", cost: 200, buildTime: 100, requiredTechnologyShortnames: [])
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
        guard let improvement = Improvement.getImprovementByName(.Faculty) else {
            XCTFail("Improvement should not be nil.")
            return
        }
        XCTAssertEqual(improvement.percentageCompleted, 0, "Component should not have any percentage completion.")
        
        let updatedImprovement = improvement.updateImprovement()
        
        XCTAssertEqual(updatedImprovement.percentageCompleted, improvement.percentageCompleted, "The improvement should not be advanced if build has not yet started.")
        
    }
    
    func testImprovementShouldComplete() throws {
        guard let improvement = Improvement.getImprovementByName(.SpaceTourism) else {
            XCTFail("Improvement should not be nil.")
            return
        }
        
        let numberOfTicksRequired = improvement.buildTime
        let buildStartedImprovement = try improvement.startBuild(startDate: Date())
        let updatedImprovement = buildStartedImprovement.updateImprovement(ticks: numberOfTicksRequired)
        
        XCTAssertGreaterThanOrEqual(updatedImprovement.percentageCompleted, 100.0, "Improvement should be done by now.")
    }
    
    func testFactoryShouldIncreaseIncome() throws {
        guard let improvement = Improvement.getImprovementByName(.SpaceTourism) else {
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
    
    func testTechFirmShouldIncreaseIncomeAndTechPoints() throws {
        let player = Player(username: "testUser")
        assert(player.improvements.count > 0)
        assert(player.improvements[0].shortName == .TechConsultancy)
        
        let updatedPlayer = player.improvements[0].applyEffectForOwner(player: player)
        
        XCTAssertGreaterThan(updatedPlayer.cash, player.cash, " cash")
        XCTAssertGreaterThan(updatedPlayer.technologyPoints, player.technologyPoints, " tech points")
    }
    
    func testUpdateOfPlayerImprovesBuildProgress() throws {
        var player = Player(username: "testUser")
        let improvement = Improvement.getImprovementByName(.SpaceTourism)!
        player.debug_setCash(improvement.cost)
        
        let buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        let updatedPlayer = buildingPlayer.updatePlayer()
        XCTAssertGreaterThan(updatedPlayer.improvements.last!.percentageCompleted, buildingPlayer.improvements.last!.percentageCompleted, "Improvement building progress should increase after update.")
    }
    
    func testUpdateOfPlayerTriggersImprovementEffect() throws {
        let player = Player(username: "testUser")
        let playerWouldGetCash = player.cashPerTick
        
        let updatedPlayer = player.updatePlayer()
        XCTAssertGreaterThan(updatedPlayer.cash, player.cash + playerWouldGetCash , "Cash")
     }
    
    func testPlayerCannotBuildImprovementWithoutPrerequisiteTech() throws {
        let player = Player(username: "testUser")
        let improvement = Improvement.getImprovementByName(.DroneDeliveryService)!
        
        XCTAssertThrowsError(try player.startBuildImprovement(improvement, startDate: Date()), "Player should not be able to build this improvement because player misses prereq technology.")
    }
    
    func testPlayerCanBuildImprovementWithPrerequisiteTech() throws {
        var player = Player(username: "testUser")
        player = player.extraTech(amount: 1_000_000)
        
        let improvement = Improvement.getImprovementByName(.DroneDeliveryService)!
        player = player.extraIncome(amount: improvement.cost)
        
        let prereqs = improvement.requiredTechnologies
        
        for prereq in prereqs {
            player = try player.investInTechnology(prereq)
        }
        
        _ = try player.startBuildImprovement(improvement, startDate: Date())
    }
    
    func testPlayerIsBuildingImprovementCannotBuildAnother() throws {
        var player = Player(username: "testUser")
        let improvement = Improvement.getImprovementByName(.Faculty)!
        player = player.extraIncome(amount: improvement.cost)
        
        var buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        XCTAssertTrue(buildingPlayer.isCurrentlyBuildingImprovement)
        
        let improvement2 = Improvement.getImprovementByName(.SpaceTourism)!
        buildingPlayer = buildingPlayer.extraIncome(amount: improvement2.cost)
        
        XCTAssertThrowsError(try buildingPlayer.startBuildImprovement(improvement2, startDate: Date())) { error in print(error) }
    }
    
    static let allTests = [
        ("testStartBuildImprovement", testStartBuildImprovement),
        ("testGetImprovementByName", testGetImprovementByName),
        ("testUpdateShouldNotAdvancePercentageComplete", testUpdateShouldNotAdvancePercentageComplete),
        ("testImprovementShouldComplete", testImprovementShouldComplete),
        ("testFactoryShouldIncreaseIncome", testFactoryShouldIncreaseIncome),
        ("testUpdateOfPlayerImprovesBuildProgress", testUpdateOfPlayerImprovesBuildProgress),
        ("testUpdateOfPlayerTriggersImprovementEffect", testUpdateOfPlayerTriggersImprovementEffect),
        ("testPlayerCannotBuildImprovementWithoutPrerequisiteTech", testPlayerCannotBuildImprovementWithoutPrerequisiteTech),
        ("testPlayerCanBuildImprovementWithPrerequisiteTech", testPlayerCanBuildImprovementWithPrerequisiteTech),
        ("testPlayerIsBuildingImprovementCannotBuildAnother", testPlayerIsBuildingImprovementCannotBuildAnother),
    ]

}

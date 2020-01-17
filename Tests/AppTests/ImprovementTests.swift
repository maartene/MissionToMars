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
        let improvement = Improvement(shortName: .Faculty, name: "Factory", description: "Test", cost: 200, buildTime: 100, requiredTechnologyShortnames: [], allowsParrallelBuild: true, rushable: true)
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
    
    /*func testTechFirmShouldIncreaseIncomeAndTechPoints() throws {
        let player = Player(username: "testUser")
        assert(player.improvements.count > 0)
        assert(player.improvements[0].shortName == .TechConsultancy)
        
        let updatedPlayer = player.improvements[0].applyEffectForOwner(player: player)
        
        XCTAssertGreaterThan(updatedPlayer.cash, player.cash, " cash")
        XCTAssertGreaterThan(updatedPlayer.technologyPoints, player.technologyPoints, " tech points")
    }*/
    
    func testUpdateOfPlayerImprovesBuildProgress() throws {
        var player = Player(username: "testUser")
        let improvement = Improvement.getImprovementByName(.CrowdFundingCampaign)!
        player.debug_setCash(improvement.cost)
        
        let buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        let updatedPlayer = buildingPlayer.updatePlayer()
        XCTAssertGreaterThan(updatedPlayer.improvements.last!.percentageCompleted, buildingPlayer.improvements.last!.percentageCompleted, "Improvement building progress should increase after update.")
    }
    
    func testUpdateOfPlayerTriggersImprovementEffect() throws {
        let improvement = Improvement.getImprovementByName(.InvestmentPortfolio_S)!
        let player = Player(username: "testUser").extraIncome(amount: improvement.cost)
        let playerWouldGetCash = player.cashPerTick
        var buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        buildingPlayer = buildingPlayer.updatePlayer(ticks: improvement.buildTime)
        
        let updatedPlayer = buildingPlayer.updatePlayer()
        print("Player would get cash: \(buildingPlayer.cashPerTick)")
        print("Cash before update: \(buildingPlayer.cash) after update: \(updatedPlayer.cash)")
        XCTAssertGreaterThan(updatedPlayer.cash, buildingPlayer.cash + playerWouldGetCash , "Cash")
     }
    
    func testPlayerCannotBuildImprovementWithoutPrerequisiteTech() throws {
        let player = Player(username: "testUser")
        let improvement = Improvement.getImprovementByName(.DroneDeliveryService)!
        
        XCTAssertThrowsError(try player.startBuildImprovement(improvement, startDate: Date()), "Player should not be able to build this improvement because player misses prereq technology.")
    }
    
    func testPlayerCanBuildImprovementWithPrerequisiteTech() throws {
        var player = Player(username: "testUser")
        player = player.extraTech(amount: 1_000_000)
        
        let improvement = Improvement.getImprovementByName(.BioResearchFacility)!
        player = player.extraIncome(amount: improvement.cost)
        
        player = try player.investInTechnology(Technology.getTechnologyByName(.AdaptiveML)!)
        
        _ = try player.startBuildImprovement(improvement, startDate: Date())
    }
    
    func testPlayerIsBuildingImprovementCannotBuildAnother() throws {
        var player = Player(username: "testUser")
        let improvement = Improvement.getImprovementByName(.Faculty)!
        player = player.extraIncome(amount: improvement.cost)
        
        var buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        XCTAssertTrue(buildingPlayer.isCurrentlyBuildingImprovement)
        
        let improvement2 = Improvement.getImprovementByName(.CrowdFundingCampaign)!
        buildingPlayer = buildingPlayer.extraIncome(amount: improvement2.cost)
        
        XCTAssertThrowsError(try buildingPlayer.startBuildImprovement(improvement2, startDate: Date())) { error in print(error) }
    }
    
    func testPlayerCanRushImprovement() throws {
        var player = Player(username: "testuser")
        let improvement = Improvement.getImprovementByName(.Faculty)!
        player = player.extraIncome(amount: improvement.cost * 2)
        
        var buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        XCTAssertEqual(buildingPlayer.currentlyBuildingImprovement!.percentageCompleted, 0, "% complete")
        
        buildingPlayer = try buildingPlayer.rushImprovement(improvement)
        
        XCTAssertEqual(buildingPlayer.improvements.last!.shortName, Improvement.ShortName.Faculty)
        XCTAssertGreaterThanOrEqual(buildingPlayer.improvements.last!.percentageCompleted, 100.0, "% complete")
        
    }
    
    func testPlayerCannotRushUnrushableImprovement() throws {
        var player = Player(username: "testuser")
        let improvement = Improvement.getImprovementByName(.InvestmentPortfolio_S)!
        player = player.extraIncome(amount: improvement.cost * 2)
        
        let buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        XCTAssertEqual(buildingPlayer.currentlyBuildingImprovement!.percentageCompleted, 0, "% complete")
        
        XCTAssertThrowsError(try buildingPlayer.rushImprovement(improvement))
    }
    
    func testPlayerCannotRushWithInsufficientFunds() throws {
        var player = Player(username: "testuser")
        let improvement = Improvement.getImprovementByName(.InvestmentPortfolio_S)!
        player = player.extraIncome(amount: improvement.cost)
        
        let buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        XCTAssertEqual(buildingPlayer.currentlyBuildingImprovement!.percentageCompleted, 0, "% complete")
        
        XCTAssertThrowsError(try buildingPlayer.rushImprovement(improvement))
    }
    
    // test static effect
    func testBuildTimeFactorShortensBuildTime() throws {
        let improvement1 = Improvement.getImprovementByName(.CrowdFundingCampaign)!
        let improvement2 = Improvement.getImprovementByName(.CrowdFundingCampaign)!
        let ikea = Improvement.getImprovementByName(.PrefabFurniture)!
        
        var player1 = Player(username: "testUser")
        player1 = player1.extraIncome(amount: improvement1.cost)
        player1 = try player1.startBuildImprovement(improvement1, startDate: Date())
        XCTAssertEqual(player1.currentlyBuildingImprovement?.percentageCompleted ?? 1.0, 0.0, "%")
        
        var player2 = Player(username: "testUser2")
        player2 = player2.extraIncome(amount: improvement2.cost + ikea.cost)
        player2 = try player2.startBuildImprovement(ikea, startDate: Date())
        player2 = player2.updatePlayer(ticks: ikea.buildTime + 1)
        XCTAssert(player2.improvements.filter { improvement in improvement.isCompleted }.contains(ikea))
        player2 = try player2.startBuildImprovement(improvement2, startDate: Date())
        XCTAssertEqual(player2.currentlyBuildingImprovement?.percentageCompleted ?? 1.0, 0.0, "%")
        player1 = player1.updatePlayer()
        player2 = player2.updatePlayer()
        
        XCTAssertGreaterThan(player2.currentlyBuildingImprovement?.percentageCompleted ?? 0, player1.currentlyBuildingImprovement?.percentageCompleted ?? 0)
        
    }
    
    // test static effect
    func testBuildingCanIncreaseBuiltTimeFactor() throws {
        let player = Player(username: "testUser")
        XCTAssertEqual(player.buildTimeFactor, 1.0)
        
        // Build Ikea store
        let ikea = Improvement.getImprovementByName(.PrefabFurniture)!
        var ikeaPlayer = player.extraIncome(amount: ikea.cost)
        ikeaPlayer = try ikeaPlayer.startBuildImprovement(ikea, startDate: Date())
        ikeaPlayer = ikeaPlayer.updatePlayer(ticks: ikea.buildTime + 1)
        
        XCTAssertLessThan(ikeaPlayer.buildTimeFactor, player.buildTimeFactor)
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
        ("testPlayerCanRushImprovement", testPlayerCanRushImprovement),
        ("testPlayerCannotRushUnrushableImprovement", testPlayerCannotRushUnrushableImprovement),
        ("testPlayerCannotRushWithInsufficientFunds", testPlayerCannotRushWithInsufficientFunds),
        ("testBuildTimeFactorShortensBuildTime", testBuildTimeFactorShortensBuildTime),
        ("testBuildingCanIncreaseBuiltTimeFactor", testBuildingCanIncreaseBuiltTimeFactor),
    ]

}

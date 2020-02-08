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
        
        let result = improvement.updateImprovement(buildPoints: 1.0)
        
        XCTAssertEqual(result.updatedImprovement.percentageCompleted, improvement.percentageCompleted, "The improvement should not be advanced if build has not yet started.")
        
    }
    
    func testImprovementShouldComplete() throws {
        guard let improvement = Improvement.getImprovementByName(.SpaceTourism) else {
            XCTFail("Improvement should not be nil.")
            return
        }
        
        let numberOfPointsRequired = Double(improvement.buildTime)
        let buildStartedImprovement = try improvement.startBuild(startDate: Date())
        let result = buildStartedImprovement.updateImprovement(buildPoints: numberOfPointsRequired)
        
        XCTAssertGreaterThanOrEqual(result.updatedImprovement.percentageCompleted, 100.0, "Improvement should be done by now.")
    }
    
    func testFactoryShouldIncreaseIncome() throws {
        guard let improvement = Improvement.getImprovementByName(.SpaceTourism) else {
            XCTFail("Improvement should not be nil.")
            return
        }
        
        let completedImprovement = try completeImprovement(improvement)
        
        let player = Player(emailAddress: "example@example.com", name: "testUser")
        
        let updatedPlayer = completedImprovement.applyEffectForOwner(player: player)
        
        XCTAssertGreaterThan(updatedPlayer.cash, player.cash, " cash")
    }

    func completeImprovement(_ improvement: Improvement) throws -> Improvement {
        let startBuildImprovement = try improvement.startBuild(startDate: Date())
        let result = startBuildImprovement.updateImprovement(buildPoints: Double(improvement.buildTime))
        
        assert(result.updatedImprovement.isCompleted, "Improvement should be completed.")
        
        return result.updatedImprovement
    }
    
    /*func testTechFirmShouldIncreaseIncomeAndTechPoints() throws {
        let player = Player(emailAddress: "example@example.com", name: "testUser")
        assert(player.improvements.count > 0)
        assert(player.improvements[0].shortName == .TechConsultancy)
        
        let updatedPlayer = player.improvements[0].applyEffectForOwner(player: player)
        
        XCTAssertGreaterThan(updatedPlayer.cash, player.cash, " cash")
        XCTAssertGreaterThan(updatedPlayer.technologyPoints, player.technologyPoints, " tech points")
    }*/
    
    func unlockTechnologiesForImprovement(player: Player, improvement: Improvement) -> Player {
        var changedPlayer = player
        for tech in improvement.requiredTechnologyShortnames {
            changedPlayer.forceUnlockTechnology(shortName: tech)
        }
        return changedPlayer
    }
    
    func testUpdateOfPlayerImprovesBuildProgress() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser")
        let improvement = Improvement.getImprovementByName(.BioTech_TAG)!
        player.debug_setCash(improvement.cost)
        
        var buildingPlayer = unlockTechnologiesForImprovement(player: player, improvement: improvement)
        buildingPlayer = try buildingPlayer.startBuildImprovement(improvement, startDate: Date())
        let updatedPlayer = buildingPlayer.updatePlayer()
        XCTAssertGreaterThan(updatedPlayer.improvements.last!.percentageCompleted, buildingPlayer.improvements.last!.percentageCompleted, "Improvement building progress should increase after update.")
    }
    
    func testUpdateOfPlayerTriggersImprovementEffect() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser")
        player = try player.removeImprovementInSlot(0)
        
        XCTAssertEqual(player.cash, player.updatePlayer().cash, "cash")
        
        let improvement = Improvement.getImprovementByName(.InvestmentBank)!
        var buildingPlayer = player.extraIncome(amount: improvement.cost)
        buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        XCTAssertEqual(player.cash, buildingPlayer.cash, "cash")
        
        buildingPlayer = buildingPlayer.updatePlayer(ticks: improvement.buildTime + 1)
        XCTAssert(buildingPlayer.completedImprovements.contains(improvement))
        
        let updatedPlayer = buildingPlayer.updatePlayer()
        XCTAssertGreaterThan(updatedPlayer.cash, buildingPlayer.cash , "Cash")
     }
    
    func testPlayerCannotBuildImprovementWithoutPrerequisiteTech() throws {
        let player = Player(emailAddress: "example@example.com", name: "testUser")
        let improvement = Improvement.getImprovementByName(.DroneDeliveryService)!
        
        XCTAssertThrowsError(try player.startBuildImprovement(improvement, startDate: Date()), "Player should not be able to build this improvement because player misses prereq technology.")
    }
    
    func testPlayerCanBuildImprovementWithPrerequisiteTech() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser")
        player = player.extraTech(amount: 1_000_000)
        
        let improvement = Improvement.getImprovementByName(.BioResearchFacility)!
        player = player.extraIncome(amount: improvement.cost)
        
        player = try player.investInTechnology(Technology.getTechnologyByName(.AdaptiveML)!)
        
        _ = try player.startBuildImprovement(improvement, startDate: Date())
    }
    
    /*func testPlayerIsBuildingImprovementCannotBuildAnother() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser")
        let improvement = Improvement.getImprovementByName(.Faculty)!
        player = player.extraIncome(amount: improvement.cost)
        
        var buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        XCTAssertTrue(buildingPlayer.isCurrentlyBuildingImprovement)
        
        let improvement2 = Improvement.getImprovementByName(.AI_TAG)!
        buildingPlayer = buildingPlayer.extraIncome(amount: improvement2.cost)
        
        XCTAssertThrowsError(try buildingPlayer.startBuildImprovement(improvement2, startDate: Date())) { error in print(error) }
    }*/
    
    func testPlayerCanRushImprovement() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser")
        let improvement = Improvement.getImprovementByName(.Faculty)!
        player = player.extraIncome(amount: improvement.cost * 2)
        
        var buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        XCTAssertEqual(buildingPlayer.currentlyBuildingImprovement!.percentageCompleted, 0, "% complete")
        
        buildingPlayer = try buildingPlayer.rushImprovement(improvement)
        
        XCTAssertEqual(buildingPlayer.improvements.last!.shortName, Improvement.ShortName.Faculty)
        XCTAssertGreaterThanOrEqual(buildingPlayer.improvements.last!.percentageCompleted, 100.0, "% complete")
        
    }
    
    func testPlayerCannotRushUnrushableImprovement() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser")
        let improvement = Improvement.getImprovementByName(.PrefabFurniture)!
        player = unlockTechnologiesForImprovement(player: player, improvement: improvement)
        player = player.extraIncome(amount: improvement.cost * 2)
        
        let buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        XCTAssertEqual(buildingPlayer.currentlyBuildingImprovement!.percentageCompleted, 0, "% complete")
        
        XCTAssertThrowsError(try buildingPlayer.rushImprovement(improvement))
    }
    
    func testPlayerCannotRushWithInsufficientFunds() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser")
        let improvement = Improvement.getImprovementByName(.PrefabFurniture)!
        player = unlockTechnologiesForImprovement(player: player, improvement: improvement)
        player = player.extraIncome(amount: improvement.cost)
        
        let buildingPlayer = try player.startBuildImprovement(improvement, startDate: Date())
        XCTAssertEqual(buildingPlayer.currentlyBuildingImprovement!.percentageCompleted, 0, "% complete")
        
        XCTAssertThrowsError(try buildingPlayer.rushImprovement(improvement))
    }
    
    // test static effect
    func testBuildTimeFactorShortensBuildTime() throws {
        let improvement1 = Improvement.getImprovementByName(.AI_TAG)!
        let improvement2 = Improvement.getImprovementByName(.AI_TAG)!
        let ikea = Improvement.getImprovementByName(.PrefabFurniture)!
        
        var player1 = Player(emailAddress: "example@example.com", name: "testUser")
        player1 = player1.extraIncome(amount: improvement1.cost)
        player1 = unlockTechnologiesForImprovement(player: player1, improvement: improvement1)
        player1 = try player1.startBuildImprovement(improvement1, startDate: Date())
        XCTAssertEqual(player1.currentlyBuildingImprovement?.percentageCompleted ?? 1.0, 0.0, "%")
        
        var player2 = Player(emailAddress: "example2@example.com", name: "testUser2")
        player2 = unlockTechnologiesForImprovement(player: player2, improvement: improvement2)
        player2 = unlockTechnologiesForImprovement(player: player2, improvement: ikea)
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
    
    func testBuildingCanShortenBuildTimeForComponent() throws {
        var player = Player(emailAddress: "testuser@user.com", name: "testuser")
        player.id = UUID()
        var mission = Mission(owningPlayerID: player.id!)
        mission.id = UUID()
        player.ownsMissionID = mission.id
        player = player.extraIncome(amount: mission.currentStage.components[1].cost)
        let result = try player.investInComponent(mission.currentStage.components[1], in: mission, date: Date())
        
        var missionWithoutBuilding = result.changedMission
        var playerWithoutBuilding = result.changedPlayer
        var stepsWithoutBuilding = 0
        while missionWithoutBuilding.currentStage.currentlyBuildingComponents.count > 0 && stepsWithoutBuilding < 100_000 {
            playerWithoutBuilding = playerWithoutBuilding.updatePlayer()
            missionWithoutBuilding = missionWithoutBuilding.updateMission(supportingPlayers: [playerWithoutBuilding])
            stepsWithoutBuilding += 1
        }
        XCTAssertEqual(missionWithoutBuilding.currentStage.completedComponents.count, 1)
        
        let improvement = Improvement.getImprovementByName(.OrbitalShipyard)!
        var playerWithBuilding = result.changedPlayer.extraIncome(amount: improvement.cost * 2)
        playerWithBuilding = unlockTechnologiesForImprovement(player: playerWithBuilding, improvement: improvement)
        playerWithBuilding = try playerWithBuilding.startBuildImprovement(improvement, startDate: Date())
        for _ in 0 ... improvement.buildTime {
            playerWithBuilding = playerWithBuilding.updatePlayer()
        }
        XCTAssert(playerWithBuilding.completedImprovements.contains(improvement))
        
        var missionWithBuilding = result.changedMission
        var stepsWithBuilding = 0
        while missionWithBuilding.currentStage.currentlyBuildingComponents.count > 0 && stepsWithBuilding < 100_000 {
            missionWithBuilding = missionWithBuilding.updateMission(supportingPlayers: [playerWithBuilding])
            stepsWithBuilding += 1
        }
        XCTAssertEqual(missionWithBuilding.currentStage.completedComponents.count, 1)
        print("Without building: \(stepsWithoutBuilding), with building: \(stepsWithBuilding)")
        XCTAssertGreaterThan(stepsWithoutBuilding, stepsWithBuilding)
    }
    
    // test static effect
    func testBuildingCanIncreaseBuiltTimeFactor() throws {
        let player = Player(emailAddress: "example@example.com", name: "testUser")
        //XCTAssertEqual(player.buildTimeFactor, 1.0)
        
        // Build Ikea store
        let ikea = Improvement.getImprovementByName(.PrefabFurniture)!
        var ikeaPlayer = player.extraIncome(amount: ikea.cost)
        ikeaPlayer = unlockTechnologiesForImprovement(player: ikeaPlayer, improvement: ikea)
        ikeaPlayer = try ikeaPlayer.startBuildImprovement(ikea, startDate: Date())
        ikeaPlayer = ikeaPlayer.updatePlayer(ticks: ikea.buildTime + 1)
        
        //XCTAssertLessThan(ikeaPlayer.buildTimeFactor, player.buildTimeFactor)
    }
    
    func testRushingImprovementDoesNotRemoveExistingImprovement() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser")
        
        let improvement = Improvement.getImprovementByName(.AI_TAG)!
        player = player.extraIncome(amount: improvement.cost * 4)
        player = unlockTechnologiesForImprovement(player: player, improvement: improvement)
        
        player = try player.startBuildImprovement(improvement, startDate: Date())
        player = player.updatePlayer(ticks: improvement.buildTime + 1)
        XCTAssertEqual(player.completedImprovements.filter({$0 == improvement}).count, 1)
        
        player = try player.startBuildImprovement(improvement, startDate: Date())
        player = try player.rushImprovement(improvement)
        
        XCTAssertEqual(player.completedImprovements.filter({$0 == improvement}).count, 2)
        
    }
    
    func testCannotBuildMoreImprovementsThanNumberOfSlots() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser")
        player = try player.removeImprovementInSlot(0)
        let improvement = Improvement.getImprovementByName(.AI_TAG)!
        player = unlockTechnologiesForImprovement(player: player, improvement: improvement)
        player = player.extraIncome(amount: improvement.cost * Double(player.improvementSlotsCount + 1))
        
        
        for _ in 0 ..< player.improvementSlotsCount {
            player = try player.startBuildImprovement(improvement, startDate: Date())
        }
        
        XCTAssertThrowsError(try player.startBuildImprovement(improvement, startDate: Date()))
    }
    
    func testSellImprovement() throws {
        var player = Player(emailAddress: "example@example.com", name: "testUser")
        let improvement = Improvement.getImprovementByName(.AI_TAG)!
        player = unlockTechnologiesForImprovement(player: player, improvement: improvement)
        player = try player.startBuildImprovement(improvement, startDate: Date())
        player = player.updatePlayer(ticks: improvement.buildTime + 1)
        XCTAssert(player.completedImprovements.contains(improvement))
        let cashBeforeSale = player.cash
        let sellingPlayer = try player.sellImprovement(improvement)
        XCTAssert(sellingPlayer.improvements.contains(improvement) == false)
        XCTAssertGreaterThan(sellingPlayer.cash, cashBeforeSale, "Cash")
        
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
        //("testPlayerIsBuildingImprovementCannotBuildAnother", testPlayerIsBuildingImprovementCannotBuildAnother),
        ("testPlayerCanRushImprovement", testPlayerCanRushImprovement),
        ("testPlayerCannotRushUnrushableImprovement", testPlayerCannotRushUnrushableImprovement),
        ("testPlayerCannotRushWithInsufficientFunds", testPlayerCannotRushWithInsufficientFunds),
        ("testBuildTimeFactorShortensBuildTime", testBuildTimeFactorShortensBuildTime),
        ("testBuildingCanIncreaseBuiltTimeFactor", testBuildingCanIncreaseBuiltTimeFactor),
        ("testRushingImprovementDoesNotRemoveExistingImprovement", testRushingImprovementDoesNotRemoveExistingImprovement),
        ("testCannotBuildMoreImprovementsThanNumberOfSlots", testCannotBuildMoreImprovementsThanNumberOfSlots),
        ("testSellImprovement", testSellImprovement)
    ]

}

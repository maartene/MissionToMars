//
//  StageTests.swift
//  AppTests
//
//  Created by Maarten Engels on 22/12/2019.
//

import Foundation

@testable import App
import Dispatch
import XCTest

class StageTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateStage() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        _ = try Stage.getStageByLevel(1)
    }
    
    func testUpdateStageShouldNotIncreasePercentageComplete() throws {
        let stage = try Stage.getStageByLevel(1)
        let updatedStage = stage.updateStage(supportingPlayers: [])
        XCTAssertEqual(updatedStage.percentageComplete, 0.0, "Without explicitly starting a build, percentageComplete should not increase.")
    }
    
    func testStartBuild() throws {
        let stage = try Stage.getStageByLevel(1)
        XCTAssertEqual(stage.components.count, stage.uncompletedComponents.count, "All components should be uncompleted.")
        XCTAssertEqual(0, stage.completedComponents.count, "No components should be completed yet.")
        XCTAssertEqual(stage.currentlyBuildingComponents.count, 0, "No component should be building.")
        
        let changedStage = try stage.startBuildingComponent(stage.components.randomElement()!, buildDate: Date(), by: Player(emailAddress: "", name: ""))
        
        XCTAssertGreaterThan(changedStage.currentlyBuildingComponents.count, 0, "A component should be building.")
        
    }
    
    func testCompleteBuild() throws {
        let stage = try Stage.getStageByLevel(1)
        XCTAssertEqual(stage.components.count, stage.uncompletedComponents.count, "All components should be uncompleted.")
        XCTAssertEqual(0, stage.completedComponents.count, "No components should be completed yet.")
        XCTAssertEqual(0, stage.currentlyBuildingComponents.count, "No component should be building.")
        
        let componentToBuild = stage.components.randomElement()!
        var player = Player(emailAddress: "", name: "")
        player.id = UUID()
        let changedStage = try stage.startBuildingComponent(componentToBuild, buildDate: Date(), by: player)
        XCTAssertEqual(1, changedStage.currentlyBuildingComponents.count, "One component should be building.")
        var updatedStage = changedStage
        for _ in 0 ... componentToBuild.buildTime {
            player = player.updatePlayer()
            updatedStage = updatedStage.updateStage(supportingPlayers: [player])
        }
        XCTAssertEqual(0, updatedStage.currentlyBuildingComponents.count, "A component should not be building.")
        XCTAssertEqual(1, updatedStage.completedComponents.count, "One component should be completed.")
        XCTAssert(updatedStage.completedComponents.contains(componentToBuild), "The component to build should be part of completedComponents")
    }

    static let allTests = [
        ("testCreateStage", testCreateStage),
        ("testUpdateStageShouldNotIncreasePercentageComplete", testUpdateStageShouldNotIncreasePercentageComplete),
        ("testStartBuild", testStartBuild),
        ("testCompleteBuild", testCompleteBuild),
    ]
}

//
//  TechnologyTests.swift
//  AppTests
//
//  Created by Maarten Engels on 31/12/2019.
//

import App
import Dispatch
import XCTest
@testable import Model

class TechnologyTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPlayerStartsWithTechnology() {
        let player = Player(username: "testuser")
        XCTAssert(player.unlockedTechnologyNames.contains(.AutonomousDriving))
    }
    
    func testPlayerHasPrerequisiteTechnologies() {
        let player = Player(username: "testUser")
        
        let unlockableTechs = Technology.unlockableTechnologiesForPlayer(player)
        let unlockableTechNames = unlockableTechs.map { tech in return tech.shortName }
        
        XCTAssert(unlockableTechNames.contains(.RadiationShielding))
        XCTAssert(unlockableTechNames.contains(.AutonomousDriving) == false, "you already have Autonomous Driving")
        XCTAssert(unlockableTechNames.contains(.AdvancedRocketry) == false, "you don't have the prerequisites for Advanced Rocketry")
    }
    
    static let allTests = [
        ("testPlayerStartsWithTechnology", testPlayerStartsWithTechnology),
    ]

}

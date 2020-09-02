//
//  TechnologyTests.swift
//  AppTests
//
//  Created by Maarten Engels on 31/12/2019.
//

@testable import App
import Dispatch
import XCTest

class TechnologyTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPlayerStartsWithTechnology() {
        let player = Player(emailAddress: "example@example.com", name: "testUser")
        XCTAssert(player.unlockedTechnologyNames.contains(.LiIonBattery))
    }
    
    func testPlayerHasPrerequisiteTechnologies() {
        let player = Player(emailAddress: "example@example.com", name: "testUser")
        
        let unlockableTechs = Technology.unlockableTechnologiesForPlayer(player)
        let unlockableTechNames = unlockableTechs.map { tech in return tech.shortName }
        
        XCTAssert(unlockableTechNames.contains(.AdaptiveML))
        XCTAssert(unlockableTechNames.contains(.LiIonBattery) == false, "you already have LiIonBattery")
        XCTAssert(unlockableTechNames.contains(.GrapheneMaterials) == false, "you don't have the prerequisites for GrapheneMaterial")
    }
    
    static let allTests = [
        ("testPlayerStartsWithTechnology", testPlayerStartsWithTechnology),
    ]

}

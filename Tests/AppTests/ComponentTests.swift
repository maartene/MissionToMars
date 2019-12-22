//
//  ComponentTests.swift
//  AppTests
//
//  Created by Maarten Engels on 22/12/2019.
//

import Foundation

import App
import Dispatch
import XCTest
@testable import Model

final class ComponentTests : XCTestCase {
    func testStartBuildComponent() throws {
        let component = Component(shortName: .Satellite, name: "testComponent", description: "", cost: 1, buildTime: 1)
        XCTAssertNil(component.buildStartedOn)
        let buildingComponent = component.startBuild(startDate: Date())
        XCTAssertNotNil(buildingComponent.buildStartedOn)
    }
    
    func testGetComponentByName() throws {
        for shortName in Component.ShortName.allCases {
            XCTAssertNotNil(Component.getComponentByName(shortName), "There should be a component for every shortName value. Even for \(shortName)")
        }
    }
    
    func testUpdateShouldAdvancePercentageComplete() throws {
        guard let component = Component.getComponentByName(.Satellite) else {
            XCTFail("Component should not be nil.")
            return
        }
        XCTAssertEqual(component.percentageCompleted, 0, "Component should not have any percentage completion.")
        
        let updatedComponent = component.updateComponent()
        
        XCTAssertGreaterThan(updatedComponent.percentageCompleted, component.percentageCompleted, "The component should have a higher percentageCompleted value after calling update.")
        
    }
    
    func testComponentShouldComplete() throws {
        guard let component = Component.getComponentByName(.Satellite) else {
            XCTFail("Component should not be nil.")
            return
        }
        
        let numberOfTicksRequired = component.buildTime
        let updatedComponent = component.updateComponent(ticks: numberOfTicksRequired)
        
        XCTAssertGreaterThanOrEqual(updatedComponent.percentageCompleted, 100.0, "Component should be done by now.")
    }
    
    static let allTests = [
        ("testStartBuildComponent", testStartBuildComponent),
        ("testGetComponentByName", testGetComponentByName),
        ("testUpdateShouldAdvancePercentageComplete", testUpdateShouldAdvancePercentageComplete),
        ("testComponentShouldComplete", testComponentShouldComplete),
    ]
}

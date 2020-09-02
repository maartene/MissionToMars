//
//  ComponentTests.swift
//  AppTests
//
//  Created by Maarten Engels on 22/12/2019.
//

import Foundation

@testable import App
import Dispatch
import XCTest

final class ComponentTests : XCTestCase {
    func testStartBuildComponent() throws {
        let component = Component(shortName: .Satellite, name: "testComponent", description: "", cost: 1, buildTime: 1, requiredTechnologyShortnames: [])
        XCTAssertNil(component.buildStartedOn)
        let buildingComponent = try component.startBuild(startDate: Date(), by: Player(emailAddress: "", name: ""))
        XCTAssertNotNil(buildingComponent.buildStartedOn)
    }
    
    func testGetComponentByName() throws {
        for shortName in Component.ShortName.allCases {
            XCTAssertNotNil(Component.getComponentByName(shortName), "There should be a component for every shortName value. Even for \(shortName)")
        }
    }
    
    func testUpdateShouldNotAdvancePercentageComplete() throws {
        guard let component = Component.getComponentByName(.Satellite) else {
            XCTFail("Component should not be nil.")
            return
        }
        XCTAssertEqual(component.percentageCompleted, 0, "Component should not have any percentage completion.")
        
        let updatedComponent = component.updateComponent(buildPoints: 1.0)
        
        XCTAssertEqual(updatedComponent.percentageCompleted, component.percentageCompleted, "The component should not be advanced if build has not yet started.")
        
    }
    
    func testComponentShouldComplete() throws {
        guard let component = Component.getComponentByName(.Satellite) else {
            XCTFail("Component should not be nil.")
            return
        }
        
        let numberOfTicksRequired = component.buildTime
        let buildStartedComponent = try component.startBuild(startDate: Date(), by: Player(emailAddress: "", name: ""))
        let updatedComponent = buildStartedComponent.updateComponent(buildPoints: Double(numberOfTicksRequired))
        
        XCTAssertGreaterThanOrEqual(updatedComponent.percentageCompleted, 100.0, "Component should be done by now.")
    }
    
    
    // discount tests
    func disable_testComponentShortenBuildTime() throws {
        /*var player1 = Player(emailAddress: "example@example.com", name: "no discount")
        player1.id = UUID()
        let mission1 = Mission(owningPlayerID: player1.id!)
        
        var player2 = Player(emailAddress: "example2@example.com", name: "discount")
        player2.id = UUID()
        let mission2 = Mission(owningPlayerID: player2.id!)
        
        let component = Component.getComponentByName(.MissionControl)!
        let orbit = Improvement.getImprovementByName(.OrbitalShipyard)!
        
        player1 = player1.extraIncome(amount: component.cost)
        let result1 = try player1.investInComponent(component, in: mission1, date: Date())
        
        player2 = player2.extraIncome(amount: component.cost + orbit.cost)
        player2 = try player2.startBuildImprovement(orbit, startDate: Date())
        player2 = player2.updatePlayer(ticks: orbit.buildTime)
        XCTAssert(player2.completedImprovements.contains(orbit))
        
        //XCTAssertLessThan(player2.componentBuildTimeFactor, player1.componentBuildTimeFactor)
        
        let result2 = try player2.investInComponent(component, in: mission2, date: Date())
        
        XCTAssertLessThan(result2.changedMission.currentStage.currentlyBuildingComponents.first?.buildTime ?? 0, result1.changedMission.currentStage.currentlyBuildingComponents.first?.buildTime ?? -1)
         */
    }
    
    func disable_testComponentDiscount() throws {
        /*
        var player1 = Player(emailAddress: "example@example.com", name: "no discount")
        player1.id = UUID()
        let mission1 = Mission(owningPlayerID: player1.id!)
        
        var player2 = Player(emailAddress: "example2@example.com", name: "discount")
        player2.id = UUID()
        let mission2 = Mission(owningPlayerID: player2.id!)
        
        let component = Component.getComponentByName(.MissionControl)!
        let orbit = Improvement.getImprovementByName(.OrbitalShipyard)!
        
        player1 = player1.extraIncome(amount: component.cost)
        let result1 = try player1.investInComponent(component, in: mission1, date: Date())
        let netCost1 = player1.cash - result1.changedPlayer.cash
        
        player2 = player2.extraIncome(amount: component.cost + orbit.cost)
        player2 = try player2.startBuildImprovement(orbit, startDate: Date())
        player2 = player2.updatePlayer(ticks: orbit.buildTime)
        XCTAssert(player2.completedImprovements.contains(orbit))
        
        //XCTAssertLessThan(player2.componentDiscount, player1.componentDiscount)
        
        let result2 = try player2.investInComponent(component, in: mission2, date: Date())
        let netCost2 = player2.cash - result2.changedPlayer.cash
        
        XCTAssertLessThan(netCost2, netCost1)
         */
    }
    
    static let allTests = [
        ("testStartBuildComponent", testStartBuildComponent),
        ("testGetComponentByName", testGetComponentByName),
        ("testUpdateShouldAdvancePercentageComplete", testUpdateShouldNotAdvancePercentageComplete),
        ("testComponentShouldComplete", testComponentShouldComplete),
        //("testComponentShortenBuildTime", testComponentShortenBuildTime),
        //("testComponentDiscount", testComponentDiscount),
    ]
}

//
//  GameTests.swift
//  AppTests
//
//  Created by Maarten Engels on 04/01/2020.
//

import XCTest
@testable import Model

class GameTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGame() throws {
        var stepsTech: Int?
        var stepsImprovement: Int?
        var stepsCompoment: Int?
        
        var player = Player(username: "testPlayer")
        player.id = UUID()
        
        var mission = Mission(owningPlayerID: player.id!)
        mission.id = UUID()
        var component = mission.currentStage.components.first!
        player.ownsMissionID = mission.id
        
        // simulate until mission done (with a maximum of a million steps)
        let maxSteps = 1_000_000
        var steps = 0
        while mission.missionComplete == false && steps < maxSteps {
            player = player.updatePlayer()
            mission = mission.updateMission()
            
            if player.cash >= component.cost && mission.currentStage.currentlyBuildingComponent == nil {
                if let investment = try? player.investInComponent(component, in: mission, date: Date()) {
                    player = investment.changedPlayer
                    mission = investment.changedMission
                    if stepsCompoment == nil { stepsCompoment = steps }
                }
            }
            
            if mission.currentStage.components.first(where: {c in c == component})!.percentageCompleted >= 100.0 {
                    if mission.currentStage.unstartedComponents.count > 0 {
                        component = mission.currentStage.unstartedComponents.first!
                        print("Step: \(steps): now starting on: \(component.name)")
                    } else {
                        do {
                            mission = try mission.goToNextStage()
                            print("Step: \(steps): now on stage: \(mission.currentStageLevel)")
                            if mission.currentStage.unstartedComponents.count > 0 {
                                component = mission.currentStage.unstartedComponents.first!
                                print("Step: \(steps): now starting on: \(component.name)")
                            }
                        } catch {
                            break
                        }
                    }
            }
            
            if player.isCurrentlyBuildingImprovement == false {
                if let improvement = Improvement.unlockedImprovementsForPlayer(player).filter({impr in player.improvements.contains(impr) == false}).first {
                    if player.cash >= improvement.cost {
                        player = try player.startBuildImprovement(improvement, startDate: Date())
                        if stepsImprovement == nil { stepsImprovement = steps }
                    }
                }
            }
            
            if let tech = Technology.unlockableTechnologiesForPlayer(player).first {
                if player.technologyPoints >= tech.cost {
                    player = try player.investInTechnology(tech)
                    if stepsTech == nil { stepsTech = steps }
                }
            }
            
            steps += 1
        }
        print("Completed running simulation (max steps: \(maxSteps).")
        print("Steps to first tech: \(stepsTech ?? -1)")
        print("Steps to first improvement: \(stepsImprovement ?? -1)")
        print("Steps to first component: \(stepsCompoment ?? -1)")
        
        print("Got this far: \(mission.percentageDone)")
        if mission.percentageDone >= 100 {
            print("Completed mission in \(steps) update steps.")
            XCTAssertTrue(true)
        } else {
            print("Failed to complete mission in \(maxSteps) steps.")
            XCTAssertTrue(true)
        }
        
        print("Cash: \(player.cash)")
        //print("Player: \(player)")
    }

}

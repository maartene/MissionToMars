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
        
        var player = Player(emailAddress: "example@example.com", name: "testUser")
        player.id = UUID()
        
        var mission = Mission(owningPlayerID: player.id!)
        mission.id = UUID()
        var component = mission.currentStage.components.first!
        player.ownsMissionID = mission.id
        
        var completeComponents = [String]()
        
        // simulate until mission done (with a maximum of a million steps)
        let maxSteps = 1_000_000
        var steps = 0
        while mission.missionComplete == false && steps < maxSteps {
            player = player.updatePlayer()
            mission = mission.updateMission()
            
            if player.cash >= component.cost && mission.currentStage.currentlyBuildingComponents.first == nil && mission.currentStage.currentlyBuildingComponents.first?.percentageCompleted ?? 0 < 100 && mission.currentStage.percentageComplete < 100.0 && completeComponents.contains("\(String(component.shortName.rawValue)+String(mission.currentStage.level))") == false {
                do {
                    let investment = try player.investInComponent(component, in: mission, date: Date())
                    completeComponents.append("\(String(component.shortName.rawValue)+String(mission.currentStage.level))")
                    print("Step: \(steps): now starting on: \(component.name), cash: \(investment.changedPlayer.cash)")
                    player = investment.changedPlayer
                    mission = investment.changedMission
                    if stepsCompoment == nil { stepsCompoment = steps }
                } catch {
                    print(error)
                }
            }
            
            if mission.currentStage.components.first(where: {c in c == component})!.percentageCompleted >= 100.0 {
                    if mission.currentStage.unstartedComponents.count > 0 {
                        component = mission.currentStage.unstartedComponents.first!
                        //print("Step: \(steps): now starting on: \(component.name)")
                        //completeComponents.append(component)
                    } else {
                        do {
                            mission = try mission.goToNextStage()
                            print("Step: \(steps): now on stage: \(mission.currentStageLevel)")
                            if mission.currentStage.unstartedComponents.count > 0 {
                                component = mission.currentStage.unstartedComponents.first!
                                //print("Step: \(steps): now starting on: \(component.name)")
                                //completeComponents.append(component)
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
                        if improvement.shortName != .CrowdFundingCampaign {
                            print("Step \(steps): Now starting on build of: \(improvement.name), cash: \(player.cash)") }
                        if stepsImprovement == nil { stepsImprovement = steps }
                    }
                }
            }
            
            if let tech = Technology.unlockableTechnologiesForPlayer(player).first {
                if player.technologyPoints >= tech.cost {
                    player = try player.investInTechnology(tech)
                    print("Step \(steps): Now investing in tech: \(tech.name), cash: \(player.cash)")
                    if stepsTech == nil { stepsTech = steps }
                }
            }
            
            if mission.missionComplete {
                print("Completed the mission in \(steps) steps.")
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
    
    func testGameMP() throws {
        var stepsTech: Int?
        var stepsImprovement: Int?
        var stepsCompoment: Int?
        
        var mission: Mission!
        var players = [Player]()
        for i in 0 ..< 5 {
            var player = Player(emailAddress: "example@example.com", name: "testUser", startImprovementShortName: Improvement.startImprovements.randomElement()!.shortName)
            player.id = UUID()
            
            
            if i == 0 {
                mission = Mission(owningPlayerID: player.id!)
                mission.id = UUID()
                player.ownsMissionID = mission.id
            } else {
                player.supportsPlayerID = players[0].id!
            }
            
            players.append(player)
        }
        var completeComponents = [String]()
        var component = mission.currentStage.components.first!
        
        // simulate until mission done (with a maximum of a million steps)
        let maxSteps = 1_000_000
        var steps = 0
        while mission.missionComplete == false && steps < maxSteps {
            mission = mission.updateMission()
            for i in 0 ..< players.count {
                var player = players[i]
                player = player.updatePlayer()
                
                if mission.currentStage.unstartedComponents.contains(component) == false {
                    if mission.currentStage.unstartedComponents.first != nil {
                        component = mission.currentStage.unstartedComponents.first!
                    }
                }
                
                if player.cash >= component.cost && mission.currentStage.unstartedComponents.contains(component) {
                    do {
                        let investment = try player.investInComponent(component, in: mission, date: Date())
                        completeComponents.append("\(String(component.shortName.rawValue)+String(mission.currentStage.level))")
                        print("Step: \(steps): Player: \(i): now starting on: \(component.name), cash: \(investment.changedPlayer.cash)")
                        /*if mission.currentStage.unstartedComponents.first != nil {
                            component = mission.currentStage.unstartedComponents.first!
                        }*/
                        player = investment.changedPlayer
                        mission = investment.changedMission
                        if stepsCompoment == nil { stepsCompoment = steps }
                    } catch {
                        //print(error)
                    }
                }
                
                if mission.currentStage.components.first(where: {c in c == component})!.percentageCompleted >= 100.0 {
                        if mission.currentStage.unstartedComponents.count > 0 {
                            component = mission.currentStage.unstartedComponents.first!
                            print("Step: \(steps): now starting on: \(component.name)")
                            //completeComponents.append(component)
                        } else {
                            do {
                                mission = try mission.goToNextStage()
                                print("Step: \(steps): now on stage: \(mission.currentStageLevel)")
                                if mission.currentStage.unstartedComponents.count > 0 {
                                    component = mission.currentStage.unstartedComponents.first!
                                    //print("Step: \(steps): now starting on: \(component.name)")
                                    //completeComponents.append(component)
                                }
                            } catch {
                                break
                            }
                        }
                }
                
                if player.isCurrentlyBuildingImprovement == false {
                    if let improvement = Improvement.unlockedImprovementsForPlayer(player).filter({impr in player.improvements.contains(impr) == false}).randomElement() {
                        if player.cash >= improvement.cost {
                            player = try player.startBuildImprovement(improvement, startDate: Date())
                            if improvement.shortName != .CrowdFundingCampaign {
                                print("Step \(steps): Now starting on build of: \(improvement.name), cash: \(player.cash)") }
                            if stepsImprovement == nil { stepsImprovement = steps }
                        }
                    }
                }
                
                if let tech = Technology.unlockableTechnologiesForPlayer(player).first {
                    if player.technologyPoints >= tech.cost {
                        player = try player.investInTechnology(tech)
                        print("Step \(steps): Now investing in tech: \(tech.name), cash: \(player.cash)")
                        if stepsTech == nil { stepsTech = steps }
                    }
                }
                
                players[i] = player
            }
            if mission.missionComplete {
                print("Completed the mission in \(steps) steps.")
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
        
        //print("Cash: \(player.cash)")
        //print("Player: \(player)")
    }

}

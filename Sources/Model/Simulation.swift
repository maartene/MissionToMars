//
//  Simulation.swift
//  MissionToMars
//
//  Created by Maarten Engels on 15/12/2019.
//

import Foundation
import FluentSQLite
import Vapor

public struct Simulation {
    public static let UPDATE_INTERVAL_IN_MINUTES = 60.0
    public static var GLOBAL_SIMULATION_ID: UUID?
    
    public var id: UUID?
    public let tickCount: Int
    public let gameDate: Date
    public let nextUpdateDate: Date
    
    public init(id: UUID? = nil, tickCount: Int, gameDate: Date, nextUpdateDate: Date) {
        self.id = id
        self.tickCount = tickCount
        self.gameDate = gameDate
        self.nextUpdateDate = nextUpdateDate
    }
    
    public func updateSimulation(currentDate: Date, players: [Player], missions: [Mission]) -> (updatedSimulation: Simulation, updatedPlayers: [Player], updatedMissions: [Mission]) {
        var updatedSimulation = self
        var updatedPlayers = players
        var updatedMissions = missions
    
        while updatedSimulation.simulationShouldUpdate(currentDate: currentDate) {
            //print("updating \(result)")
            let nextUpdateDate = updatedSimulation.nextUpdateDate.addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60)
            //let nextUpdateDate = updatedSimulation.nextUpdateDate.addingTimeInterval(0.1)
            let gameDate = updatedSimulation.gameDate.addingTimeInterval(24*60*60)
            let tickCount = updatedSimulation.tickCount + 1
            
            updatedPlayers = updatedPlayers.map { player in
                player.updatePlayer()
            }
            
            updatedMissions = updatedMissions.map { mission in
                mission.updateMission()
            }
            
            updatedSimulation = Simulation(id: self.id, tickCount: tickCount, gameDate: gameDate, nextUpdateDate: nextUpdateDate)
        }
        
        return (updatedSimulation, updatedPlayers, updatedMissions)
    }
    
    public func simulationShouldUpdate(currentDate: Date) -> Bool {
        return currentDate >= self.nextUpdateDate
    }
    
}

extension Simulation: Content { }
extension Simulation: SQLiteUUIDModel { }
extension Simulation: Migration { }

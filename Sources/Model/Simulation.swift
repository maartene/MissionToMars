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
    
    public var gameDateString: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMMyyyy")
        //print("gameDate: \(gameDate) gameDateString \(formatter.string(from: gameDate))")
        return formatter.string(from: gameDate)
    }
    
    public init(id: UUID? = nil, tickCount: Int, gameDate: Date, nextUpdateDate: Date) {
        self.id = id
        self.tickCount = tickCount
        self.gameDate = gameDate
        self.nextUpdateDate = nextUpdateDate
    }
    
    public func update(currentDate: Date, players: [Player]) -> (updatedSimulation: Simulation, updatedPlayers: [Player]) {
        var updatedSimulation = self
        var updatedPlayers = players
    
        while updatedSimulation.simulationShouldUpdate(currentDate: currentDate) {
            //print("updating \(result)")
            let nextUpdateDate = updatedSimulation.nextUpdateDate.addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60)
            let gameDate = updatedSimulation.gameDate.addingTimeInterval(24*60*60)
            let tickCount = updatedSimulation.tickCount + 1
            
            updatedPlayers = updatedPlayers.map { player in
                player.update()
            }
            
            updatedSimulation = Simulation(id: self.id, tickCount: tickCount, gameDate: gameDate, nextUpdateDate: nextUpdateDate)
        }
        
        return (updatedSimulation, updatedPlayers)
    }
    
    public func simulationShouldUpdate(currentDate: Date) -> Bool {
        return currentDate >= self.nextUpdateDate
    }
    
}

extension Simulation: Content { }
extension Simulation: SQLiteUUIDModel { }
extension Simulation: Migration { }

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
    
    public var id: UUID?
    public let tickCount: Int
    public let gameDate: Date
    public let nextUpdateDate: Date
    
    public func update(currentDate: Date, updateAction: (() -> ())?) -> Simulation {
        var result = self
    
        while currentDate >= result.nextUpdateDate {
            //print("updating \(result)")
            let nextUpdateDate = result.nextUpdateDate.addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60)
            let gameDate = result.gameDate.addingTimeInterval(24*60*60)
            let tickCount = result.tickCount + 1
            
            updateAction?()
            
            result = Simulation(tickCount: tickCount, gameDate: gameDate, nextUpdateDate: nextUpdateDate)
        }
        
        return result
    }
    
}

extension Simulation: Content { }
extension Simulation: SQLiteUUIDModel { }
extension Simulation: Migration { }

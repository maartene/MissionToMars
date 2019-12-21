//
//  Mission.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation
import FluentSQLite
import Vapor

public struct Mission: Content, SQLiteUUIDModel {
    public var id: UUID?
    
    public var missionName: String// = "Mission To Mars"// #\(Int.random(in: 1...1_000_000))"
    public let owningPlayerID: UUID
    
    public var percentageDone: Double = 0
    public var successChance: Double = 0
    
    public init(owningPlayerID: UUID) {
        self.owningPlayerID = owningPlayerID
        self.missionName = "Mission To Mars #\(Int.random(in: 1...1_000_000))"
    }
    
    
}

extension Mission: Migration { }

extension Mission {
    public func getOwningPlayer(on conn: DatabaseConnectable) throws -> Future<Player> {
        return Player.find(owningPlayerID, on: conn).map(to: Player.self) { player in
            guard let player = player else {
                throw Player.PlayerError.userDoesNotExist
            }
            
            return player
        }
    }
}

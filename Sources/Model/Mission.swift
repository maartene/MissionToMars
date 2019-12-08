//
//  Mission.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation

struct Mission {
    var id: UUID?
    
    let name = "Mission To Mars #\(Int.random(in: 1...1_000_000))"
    
    var percentageDone: Double = 0
    var successChance: Double = 0
    
    
}

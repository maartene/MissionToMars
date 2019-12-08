//
//  Improvement.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation

struct Improvement {
    var id: UUID?
    
    let name: String
    let ownerID: UUID
    
    func update() -> Improvement {
        return self
    }
}

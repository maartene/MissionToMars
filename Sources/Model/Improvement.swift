//
//  Improvement.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation
import Vapor

struct Improvement: Content {
    public var id: UUID?
    
    public let name: String
    public let ownerID: UUID
    
    func update() -> Improvement {
        return self
    }
}

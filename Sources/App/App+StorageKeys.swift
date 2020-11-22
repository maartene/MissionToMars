//
//  File.swift
//  
//
//  Created by Maarten Engels on 22/11/2020.
//

import Foundation
import Vapor

extension Application {
    struct ErrorMessages: StorageKey {
        typealias Value = [UUID: String?]
    }
    
    struct InfoMessages: StorageKey {
        typealias Value = [UUID: String?]
    }
    
    var errorMessages: [UUID: String?] {
        get { guard let messages = self.storage[ErrorMessages.self] else {
                self.storage[InfoMessages.self] = [UUID: String?]()
                return [:]
            }
            return messages
        }
        set { self.storage[ErrorMessages.self] = newValue }
    }
    
    var infoMessages: [UUID: String?] {
        get { guard let messages = self.storage[InfoMessages.self] else {
                self.storage[InfoMessages.self] = [UUID: String?]()
                return [:]
            }
            return messages
        }
        set { self.storage[InfoMessages.self] = newValue }
    }
    
    var simulation: Simulation {
        get { self.storage[Simulation.self]! }
        set { self.storage[Simulation.self] = newValue }
    }
}

extension Simulation: StorageKey {
    public typealias Value = Simulation
}

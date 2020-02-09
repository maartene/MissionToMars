//
//  Utilities.swift
//  App
//
//  Created by Maarten Engels on 09/02/2020.
//

import Foundation

public func cashFormatter(_ double: Double) -> String {
    if double / 1_000_000_000.0 > 1 {
        return "\(String(format: "%.2f", double / 1_000_000_000.0)) billion"
    } else if double / 1_000_000.0 > 1 {
        return "\(String(format: "%.2f", double / 1_000_000.0)) million"
    } else if double / 1_000.0 > 1 {
        return "\(String(format: "%.2f", double / 1_000.0)) thousand"
    } else {
        return String(format: "%.2f", double)
    }
}

//
//  Utilities.swift
//  App
//
//  Created by Maarten Engels on 09/02/2020.
//

import Foundation

public func cashFormatter(_ double: Double) -> String {
    if abs(double) >= Double(Int.max) {
        return "Unfathomable!"
    } else if double / 1_000_000_000_000.0 >= 1 {
        if Int(double) % 1_000_000_000_000 == 0 {
            return "\(String(Int(double / 1_000_000_000_000.0)))T"
        } else {
            return "\(String(format: "%.2f", double / 1_000_000_000_000.0))T"
        }
    } else if double / 1_000_000_000.0 >= 1 {
        if Int(double) % 1_000_000_000 == 0 {
            return "\(String(Int(double / 1_000_000_000.0)))B"
        } else {
            return "\(String(format: "%.2f", double / 1_000_000_000.0))B"
        }
    } else if double / 1_000_000.0 >= 1 {
        if Int(double) % 1_000_000 == 0 {
            return "\(String(Int(double / 1_000_000.0)))M"
        } else {
            return "\(String(format: "%.2f", double / 1_000_000.0))M"
        }
    } else if double / 1_000.0 >= 1 {
        if Int(double) % 1_000 == 0 {
            return "\(String(Int(double / 1_000.0)))K"
        } else {
            return "\(String(format: "%.2f", double / 1_000.0))K"
        }
    } else {
        return String(Int(double))
    }
}

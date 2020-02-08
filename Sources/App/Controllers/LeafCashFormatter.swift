//
//  LeafCashFormatter.swift
//  App
//
//  Created by Maarten Engels on 24/12/2019.
//

import Async
import Leaf

public final class CashTag: TagRenderer {
    public func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        try tag.requireParameterCount(1)
        
        return Future.map(on: tag.container) {
            if let double = tag.parameters[0].double {
                
                if double / 1_000_000_000.0 > 1 {
                    return .string("\(String(format: "%.2f", double / 1_000_000_000.0)) billion")
                } else if double / 1_000_000.0 > 1 {
                    return .string("\(String(format: "%.2f", double / 1_000_000.0)) million")
                } else if double / 1_000.0 > 1 {
                    return .string("\(String(format: "%.2f", double / 1_000.0)) thousand")
                } else {
                    return .string(String(format: "%.2f", double))
                }
            } else {
                return .null
            }
        }
    }
}

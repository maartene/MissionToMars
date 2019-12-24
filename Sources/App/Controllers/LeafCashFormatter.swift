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
                let cashInt = Int(double)
                if cashInt / 1_000_000 > 1 {
                    return .string(String("\(cashInt / 1_000_000) million"))
                } else if cashInt / 1_000 > 1 {
                    return .string(String("\(cashInt / 1_000) thousand"))
                } else {
                    return .string(String(cashInt))
                }
            } else {
                return .null
            }
        }
    }
}

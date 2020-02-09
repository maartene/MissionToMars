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
                return .string(cashFormatter(double))
            } else {
                return .null
            }
        }
    }
}

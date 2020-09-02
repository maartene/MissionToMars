//
//  LeafCashFormatter.swift
//  App
//
//  Created by Maarten Engels on 24/12/2019.
//

import Vapor
import Leaf

public struct CashTag: LeafTag {
    static let name = "cash"
    public func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
        if let double = ctx.parameters[0].double {
            return .string(cashFormatter(double))
        } else {
            return .trueNil
        }
    }
}

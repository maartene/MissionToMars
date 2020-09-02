//
//  LeafDecimalTag.swift
//  App
//
//  Created by Maarten Engels on 24/12/2019.
//

import Foundation

import Leaf

public struct DecimalTag: LeafTag {
    static let name = "decimal"
    
    public func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
        
        if let double = ctx.parameters[0].double {
            return .string(String(format: "%.2f", double))
        } else {
            return .trueNil
        }
    }
}

public struct ZeroDecimalTag: LeafTag {
    static let name = "deczero"
    
    public func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
        
        if let double = ctx.parameters[0].double {
            return .string(String(Int(double)))
        } else {
            return .trueNil
        }
    }
}

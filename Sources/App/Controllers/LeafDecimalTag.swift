//
//  LeafDecimalTag.swift
//  App
//
//  Created by Maarten Engels on 24/12/2019.
//

import Foundation

import Async
import Leaf

public final class DecimalTag: TagRenderer {
    public func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        try tag.requireParameterCount(1)
        
        return Future.map(on: tag.container) {
            if let double = tag.parameters[0].double {
                return .string(String(format: "%.2f", double))
            } else {
                return .null
            }
        }
    }
}

public final class ZeroDecimalTag: TagRenderer {
    public func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        try tag.requireParameterCount(1)
        
        return Future.map(on: tag.container) {
            if let double = tag.parameters[0].double {
                return .string(String(Int(double)))
            } else {
                return .null
            }
        }
    }
}

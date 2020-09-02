//
//  LeafComponentTag.swift
//  App
//
//  Created by Maarten Engels on 01/01/2020.
//

import Foundation
import Leaf

public struct ComponentPrereqTag: LeafTag {
    static let name = "compPrereqs"
    
    public func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
        
        if let shortName = Component.ShortName.init(rawValue: ctx.parameters[0].string ?? "") {
            if let component = Component.getComponentByName(shortName) {
                let prereqString = component.requiredTechnologies.map({tech in tech.name}).joined(separator: " ")
                return .string(prereqString)
            }
        }
        return .trueNil
    }
}

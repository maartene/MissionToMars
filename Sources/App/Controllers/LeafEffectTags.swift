//
//  LeafEffectTags.swift
//  App
//
//  Created by Maarten Engels on 08/02/2020.
//

import Foundation
import Leaf

public struct ImprovementEffectTag: LeafTag {
    static let name = "improvementEffects"
    
    public func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
        
        if let improvementShortName = Improvement.ShortName(rawValue: ctx.parameters[0].int ?? -1) {
            if let improvement = Improvement.getImprovementByName(improvementShortName) {
                return .string(improvement.effectDescription)
            }
        }
        
        return .trueNil
    }
}

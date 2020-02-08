//
//  LeafEffectTags.swift
//  App
//
//  Created by Maarten Engels on 08/02/2020.
//

import Foundation
import Async
import Leaf
import Model

public final class ImprovementEffectTag: TagRenderer {
    public func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        try tag.requireParameterCount(1)
        
        return Future.map(on: tag.container) {
            if let improvementShortName = Improvement.ShortName(rawValue: tag.parameters[0].int ?? -1) {
                if let improvement = Improvement.getImprovementByName(improvementShortName) {
                    return .string(improvement.effectDescription)
                }
            }
            
            return .null
        }
    }
}

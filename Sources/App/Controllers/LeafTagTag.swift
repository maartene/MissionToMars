//
//  LeafTagTag.swift
//  App
//
//  Created by Maarten Engels on 05/02/2020.
//

import Foundation
import Async
import Leaf
import Model

public final class ImprovementTagTag: TagRenderer {
    public func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        try tag.requireParameterCount(1)
        
        return Future.map(on: tag.container) {
            if let improvementTag = Tag.init(rawValue: tag.parameters[0].int ?? -1) {
                switch improvementTag {
                case .AI:
                    return .string("AI")
                case .Biotech:
                    return .string("Biotech")
                case .Construction:
                    return .string("Construction")
                case .Finance:
                    return .string("Finance")
                case .SpaceTravel:
                    return .string("Space Travel")
                case .Retail:
                    return .string("Retail")
                }
            }
            
            return .null
        }
    }
}

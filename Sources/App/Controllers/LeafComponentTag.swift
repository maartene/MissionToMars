//
//  LeafComponentTag.swift
//  App
//
//  Created by Maarten Engels on 01/01/2020.
//

import Foundation
import Async
import Leaf
import Model

public final class ComponentPrereqTag: TagRenderer {
    public func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        try tag.requireParameterCount(1)
        
        return Future.map(on: tag.container) {
            if let shortName = Component.ShortName.init(rawValue: tag.parameters[0].string ?? "") {
                if let component = Component.getComponentByName(shortName) {
                    let prereqString = component.requiredTechnologies.map({tech in tech.name}).joined(separator: " ")
                    return .string(prereqString)
                }
            }
            
            return .null
        }
    }
}

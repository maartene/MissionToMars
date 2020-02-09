//
//  LeafTechnologyTag.swift
//  App
//
//  Created by Maarten Engels on 09/02/2020.
//

import Foundation
import Async
import Leaf
import Model

public final class TechnologyUnlocksImprovementsTag: TagRenderer {
    public func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        try tag.requireParameterCount(1)
        
        return Future.map(on: tag.container) {
            if let techShortName = Technology.ShortName(rawValue: tag.parameters[0].int ?? -1) {
                let unlockedImprovements = Improvement.allImprovements.filter { improvement in
                    improvement.requiredTechnologyShortnames.contains(techShortName)
                }
                
                if unlockedImprovements.count == 0 {
                    return .string("-")
                }
                
                let unlockedImprovementNames = unlockedImprovements.map { $0.name }
                return .string(unlockedImprovementNames.joined(separator: ", "))
            }
            
            return .null
        }
    }
}

public final class TechnologyUnlocksTechnologiesTag: TagRenderer {
    public func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        try tag.requireParameterCount(1)
        
        return Future.map(on: tag.container) {
            if let techShortName = Technology.ShortName(rawValue: tag.parameters[0].int ?? -1) {
                let unlockedTechs = Technology.allTechnologies.filter { tech in
                    tech.prerequisites.contains(techShortName)
                }
                
                if unlockedTechs.count == 0 {
                    return .string("-")
                }
                
                let unlockedTechNames = unlockedTechs.map { $0.name }
                return .string(unlockedTechNames.joined(separator: ", "))
            }
            
            return .null
        }
    }
}

public final class TechnologyUnlocksComponentsTag: TagRenderer {
    public func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        try tag.requireParameterCount(1)
        
        return Future.map(on: tag.container) {
            if let techShortName = Technology.ShortName(rawValue: tag.parameters[0].int ?? -1) {
                let unlockedComponents = Component.allComponents.filter { comp in
                    comp.requiredTechnologyShortnames.contains(techShortName)
                }
                
                if unlockedComponents.count == 0 {
                    return .string("-")
                }
                
                let unlockedComponentNames = unlockedComponents.map { $0.name }
                return .string(unlockedComponentNames.joined(separator: ", "))
            }
            
            return .null
        }
    }
}

//
//  LeafTechnologyTag.swift
//  App
//
//  Created by Maarten Engels on 09/02/2020.
//


import Foundation
import Leaf

public struct TechnologyUnlocksImprovementsTag: LeafTag {
    static let name = "techUnlocksImprovements"
    public func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
        
        if let techShortName = Technology.ShortName(rawValue: ctx.parameters[0].int ?? -1) {
            let unlockedImprovements = Improvement.allImprovements.filter { improvement in
                improvement.requiredTechnologyShortnames.contains(techShortName)
            }
            
            if unlockedImprovements.count == 0 {
                return .string("-")
            }
            
            let unlockedImprovementNames = unlockedImprovements.map { $0.name }
            return .string(unlockedImprovementNames.joined(separator: ", "))
        }
        
        return ""
    }
}

public struct TechnologyUnlocksTechnologiesTag: LeafTag {
    static let name = "techUnlocksTechnologies"
    
    public func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
        
        if let techShortName = Technology.ShortName(rawValue: ctx.parameters[0].int ?? -1) {
            let unlockedTechs = Technology.allTechnologies.filter { tech in
                tech.prerequisites.contains(techShortName)
            }
            
            if unlockedTechs.count == 0 {
                return .string("-")
            }
            
            let unlockedTechNames = unlockedTechs.map { $0.name }
            return .string(unlockedTechNames.joined(separator: ", "))
        }
        
        return ""
    }
}

public struct TechnologyUnlocksComponentsTag: LeafTag {
    static let name = "techUnlocksComponents"
    
    public func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
    
        if let techShortName = Technology.ShortName(rawValue: ctx.parameters[0].int ?? -1) {
            let unlockedComponents = Component.allComponents.filter { comp in
                comp.requiredTechnologyShortnames.contains(techShortName)
            }
            
            if unlockedComponents.count == 0 {
                return .string("-")
            }
            
            let unlockedComponentNames = unlockedComponents.map { $0.name }
            return .string(unlockedComponentNames.joined(separator: ", "))
        }
        
        return ""
    }
}

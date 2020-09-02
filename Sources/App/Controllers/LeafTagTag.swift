//
//  LeafTagTag.swift
//  App
//
//  Created by Maarten Engels on 05/02/2020.
//

import Foundation
import Leaf

public struct ImprovementTagTag: LeafTag {
    static let name = "tag"
    
    public func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
        
        if let improvementTag = Tag.init(rawValue: ctx.parameters[0].int ?? -1) {
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
        
        return .trueNil
    }
}

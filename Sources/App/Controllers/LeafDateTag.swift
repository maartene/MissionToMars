//
//  LeafDateTag.swift
//  App
//
//  Created by Maarten Engels on 24/12/2019.
//

import Vapor
import Leaf

public struct DateTag: LeafTag {
    static let name = "date"
    
    public func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
        
        if let dateDouble = ctx.parameters[0].double {
            let date = Date(timeIntervalSince1970: dateDouble)
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMMMdyyyy")
            //print("gameDate: \(gameDate) gameDateString \(formatter.string(from: gameDate))")
            return .string(formatter.string(from: date))
        } else {
            return .trueNil
        }
    }
}

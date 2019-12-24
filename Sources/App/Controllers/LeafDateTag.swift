//
//  LeafDateTag.swift
//  App
//
//  Created by Maarten Engels on 24/12/2019.
//

import Async
import Leaf

public final class DateTag: TagRenderer {
    public func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        try tag.requireParameterCount(1)
        
        return Future.map(on: tag.container) {
            if let dateDouble = tag.parameters[0].double {
                let date = Date(timeIntervalSince1970: dateDouble)
                let formatter = DateFormatter()
                formatter.setLocalizedDateFormatFromTemplate("MMMMdyyyy")
                //print("gameDate: \(gameDate) gameDateString \(formatter.string(from: gameDate))")
                return .string(formatter.string(from: date))
            } else {
                return .null
            }
        }
    }
}

//
//  AbilityTests.swift
//  
//
//  Created by Maarten Engels on 26/11/2020.
//

import Foundation

@testable import App
import Dispatch
import XCTest

final class AbilityTests : XCTestCase {
    
    func testCooldown() throws {
        let ability = ActivatedAbility(name: "testAbility", effects: [.extraIncomeFlat(amount: 19)], cooldown: 60, lastActivation: nil)
        
        XCTAssertTrue(ability.canTrigger)
        
        let player = Player(emailAddress: "test@example.com", name: "testUser", password: "Foo")
        let triggerResult = try ability.trigger(player)
        
        XCTAssertFalse(triggerResult.updatedAbility.canTrigger)
    }
    
    static let allTests = [
        ("testCooldown", testCooldown)
    ]
}

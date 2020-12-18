//
//  CashFormatterTests.swift
//  
//
//  Created by Maarten Engels on 18/12/2020.
//

import Foundation
import XCTest
@testable import App

final class CashFormatterTests : XCTestCase {
    func testBelow1000() {
        let result = cashFormatter(500)
        print(result)
        XCTAssertEqual(result, "500")
    }
    
    func testExactly1000() {
        let result = cashFormatter(1000)
        print(result)
        XCTAssertEqual(result, "1K")
    }
    
    func testOver1000() {
        let result = cashFormatter(1500)
        print(result)
        XCTAssertEqual(result, "1.50K")
    }
    
    func testUnder1000000() {
        let result = cashFormatter(900_000)
        print(result)
        XCTAssertEqual(result, "900K")
    }
    
    func testExactly1000000() {
        let result = cashFormatter(1_000_000)
        print(result)
        XCTAssertEqual(result, "1M")
    }
    
    func testOver1000000() {
        let result = cashFormatter(1_250_420)
        print(result)
        XCTAssertEqual(result, "1.25M")
    }
    
    func testUnder1000000000() {
        let result = cashFormatter(900_250_420)
        print(result)
        XCTAssertEqual(result, "900.25M")
    }
    
    func testExactly1000000000() {
        let result = cashFormatter(1_000_000_000)
        print(result)
        XCTAssertEqual(result, "1B")
    }
    
    func testOver1000000000() {
        let result = cashFormatter(1_900_250_420)
        print(result)
        XCTAssertEqual(result, "1.90B")
    }
    
    func testMuchOver1000000000() {
        let result = cashFormatter(900_900_250_420)
        print(result)
        XCTAssertEqual(result, "900.90B")
    }
    
    static let allTests = [
        ("testBelow1000", testBelow1000),
        ("testExactly1000", testExactly1000),
        ("testOver1000", testOver1000),
        ("testUnder1000000", testUnder1000000),
        ("testExactly1000000", testExactly1000000),
        ("testOver1000000", testOver1000000),
        ("testUnder1000000000", testUnder1000000000),
        ("testExactly1000000000", testExactly1000000000),
        ("testOver1000000000", testOver1000000000),
        ("testMuchOver1000000000", testMuchOver1000000000)
    ]
}

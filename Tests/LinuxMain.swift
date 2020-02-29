import XCTest
// 1
@testable import AppTests

// 2
XCTMain([
  testCase(AppTests.allTests),
  testCase(PlayerTests.allTests),
  testCase(SimulationTests.allTests),
  testCase(ComponentTests.allTests),
  testCase(StageTests.allTests),
  testCase(ImprovementTests.allTests),
  testCase(TechnologyTests.allTests),
])

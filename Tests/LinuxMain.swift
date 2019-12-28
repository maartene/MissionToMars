import XCTest
// 1
@testable import AppTests

// 2
XCTMain([
  testCase(AppTests.allTests),
  testCase(PlayerTests.allTests),
  testCase(PlayerDBTests.allTests),
  testCase(SimulationTests.allTests),
  testCase(SimulationDBTests.allTests),
  testCase(PerformanceTests.allTests),
  testCase(ComponentTests.allTests),
  testCase(StageTests.allTests),
  testCase(ImprovementTests.allTests),
])

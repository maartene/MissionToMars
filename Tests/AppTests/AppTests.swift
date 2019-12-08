import App
import Dispatch
import XCTest
@testable import Model

final class AppTests : XCTestCase {
    func testNothing() throws {
        XCTAssert(true)
    }
    
    func testUpdatePlayer() throws {
        let player = Player(username: "testUser")
        
        let updatedPlayer = player.update()
        
        XCTAssertGreaterThan(updatedPlayer.cash, player.cash, " cash")
        XCTAssertGreaterThan(updatedPlayer.technology, player.technology, " cash")
    }
    
    func testDonateCashToPlayer() throws {
        let givingPlayer = Player(username: "givingPlayer")
        let receivingPlayer = Player(username: "receivingPlayer")
        
        let updatedPlayers = givingPlayer.donate(cash: 10, to: receivingPlayer)
        
        XCTAssertGreaterThan(updatedPlayers.receivingPlayer.cash, receivingPlayer.cash, " cash")
        XCTAssertLessThan(updatedPlayers.donatingPlayer.cash, givingPlayer.cash, " cash")
    }
    
    func testDonateTechnologyToPlayer() throws {
        let givingPlayer = Player(username: "givingPlayer")
        let receivingPlayer = Player(username: "receivingPlayer")
        
        let updatedPlayers = givingPlayer.donate(technology: 10, to: receivingPlayer)
        
        XCTAssertGreaterThan(updatedPlayers.receivingPlayer.technology, receivingPlayer.technology, " tech points")
        XCTAssertLessThan(updatedPlayers.donatingPlayer.technology, givingPlayer.technology, " tech points")
    }
    
    

    static let allTests = [
        ("testNothing", testNothing),
        ("testUpdatePlayer", testUpdatePlayer),
        ("testDonateCashToPlayer", testDonateCashToPlayer),
        ("testDonateTechnologyToPlayer", testDonateTechnologyToPlayer),
    ]
}

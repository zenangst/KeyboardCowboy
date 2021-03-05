@testable import Keyboard_Cowboy
import XCTest

class DropCommandsControllerTests: XCTestCase {
  func testGeneratingUrlCommand() {
    let result = DropCommandsController.generateCommands(from: [
      URL(string: "https://github.com/zenangst/KeyboardCowboy")!
    ], applications: [])

    XCTAssertEqual(result.first!.name,
                   "Open github.com/zenangst/KeyboardCowboy")    
  }
}

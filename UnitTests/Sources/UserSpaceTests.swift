import XCTest
@testable import Keyboard_Cowboy

final class UserSpaceTests: XCTestCase {
  func testResolveKeys() async {
    let input = """
Directory: $\(UserSpace.EnvironmentKey.directory.rawValue)
"""
    let keys = UserSpace.resolveEnvironmentKeys(input)

    XCTAssertEqual(keys, [UserSpace.EnvironmentKey.directory])
  }
}

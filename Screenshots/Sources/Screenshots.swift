@testable import ViewKit
import Keyboard_Cowboy
import SnapshotTesting
import XCTest

class Screenshots: XCTestCase {
  func testAppScreenshot() {
    assertScreenshot(
      from: MainView_Previews.self,
      size: CGSize(width: 320, height: 480)
    )
  }
}

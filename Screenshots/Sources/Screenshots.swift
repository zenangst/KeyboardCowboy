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

  func testGroupScreenshot() {
    assertScreenshot(
      from: GroupList_Previews.self,
      size: CGSize(width: 320, height: 480)
    )
  }

  func testWorkflowScreenshot() {
    assertScreenshot(
      from: WorkflowList_Previews.self,
      size: CGSize(width: 300, height: 400)
    )
  }

  func testKeyboardShortcutsScreenshot() {
    assertScreenshot(
      from: KeyboardShortcutList_Previews.self,
      size: CGSize(width: 300, height: 400)
    )
  }
}

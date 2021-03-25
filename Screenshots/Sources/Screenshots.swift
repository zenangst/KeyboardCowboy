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

  func testAppsIconScreenshot() {
    assertScreenshot(
      from: AppsIcon_Previews.self,
      size: CGSize(width: 57, height: 57),
      redacted: false,
      transparent: true
    )
  }

  func testFolderIconScreenshot() {
    assertScreenshot(
      from: FolderIcon_Previews.self,
      size: CGSize(width: 57, height: 57),
      redacted: false,
      transparent: true
    )
  }

  func testCommandKeyIconScreenshot() {
    assertScreenshot(
      from: CommandKeyIcon_Previews.self,
      size: CGSize(width: 57, height: 57),
      redacted: false,
      transparent: true
    )
  }

  func testScriptIconScreenshot() {
    assertScreenshot(
      from: ScriptIcon_Previews.self,
      size: CGSize(width: 57, height: 57),
      redacted: false,
      transparent: true
    )
  }

  func testURLIconScreenshot() {
    assertScreenshot(
      from: URLIcon_Previews.self,
      size: CGSize(width: 57, height: 57),
      redacted: false,
      transparent: true
    )
  }
}

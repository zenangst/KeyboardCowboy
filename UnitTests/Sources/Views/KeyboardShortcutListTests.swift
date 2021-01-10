@testable import ViewKit
import Keyboard_Cowboy
import SnapshotTesting
import XCTest

class KeyboardShortcutListTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: KeyboardShortcutList_Previews.self,
      size: CGSize(width: 300, height: 400)
    )
  }
}

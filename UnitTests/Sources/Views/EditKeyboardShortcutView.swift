@testable import ViewKit
import XCTest

class EditKeyboardShortcutViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: EditKeyboardShortcutView_Previews.self,
      size: CGSize(width: 600, height: 400)
    )
  }
}

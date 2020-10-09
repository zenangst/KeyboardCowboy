@testable import ViewKit
import XCTest

class EditAppleScriptViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: EditAppleScriptView_Previews.self,
      size: CGSize(width: 600, height: 400)
    )
  }
}

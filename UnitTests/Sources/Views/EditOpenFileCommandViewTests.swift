@testable import ViewKit
import XCTest

class EditOpenFileCommandViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: EditOpenFileCommandView_Previews.self,
      size: CGSize(width: 600, height: 400)
    )
  }
}

@testable import ViewKit
import XCTest

class EditOpenURLCommandViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: EditOpenURLCommandView_Previews.self,
      size: CGSize(width: 600, height: 400)
    )
  }
}

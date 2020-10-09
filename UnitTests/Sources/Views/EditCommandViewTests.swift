@testable import ViewKit
import XCTest

class EditCommandViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: EditCommandView_Previews.self,
      size: CGSize(width: 600, height: 400)
    )
  }
}

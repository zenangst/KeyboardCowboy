@testable import ViewKit
import XCTest

class EditApplicationCommandViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: EditApplicationCommandView_Previews.self,
      size: CGSize(width: 600, height: 400)
    )
  }
}

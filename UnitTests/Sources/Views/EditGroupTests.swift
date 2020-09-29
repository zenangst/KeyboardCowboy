@testable import ViewKit
import XCTest

class EditGroupTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: EditGroup_Previews.self,
      size: CGSize(width: 450, height: 160)
    )
  }
}

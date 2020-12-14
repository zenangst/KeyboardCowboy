@testable import ViewKit
import XCTest

class GroupListTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: GroupList_Previews.self,
      size: CGSize(width: 250, height: 400)
    )
  }
}

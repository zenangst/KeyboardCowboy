@testable import ViewKit
import XCTest

class GroupListTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: GroupList_Previews.self,
      size: CGSize(width: GroupList.idealWidth, height: 400)
    )
  }
}

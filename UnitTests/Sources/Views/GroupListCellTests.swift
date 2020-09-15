@testable import ViewKit
import XCTest

class GroupListCellTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(from: GroupListCell_Previews.self, size: CGSize(width: 200, height: 40))
  }
}

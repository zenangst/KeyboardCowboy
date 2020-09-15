@testable import ViewKit
import XCTest

class WorkflowListCellTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: WorkflowListCell_Previews.self,
      size: CGSize(width: 300, height: 40)
    )
  }
}

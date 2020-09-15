@testable import ViewKit
import XCTest

class WorkflowListTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: WorkflowList_Previews.self,
      size: CGSize(width: WorkflowList.idealWidth, height: 400)
    )
  }
}

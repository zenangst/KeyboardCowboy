@testable import ViewKit
import XCTest

class WorkflowViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: WorkflowView_Previews.self,
      size: CGSize(width: WorkflowView.idealWidth, height: 400)
    )
  }
}

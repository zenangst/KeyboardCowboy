@testable import ViewKit
import XCTest

class DetailViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: DetailView_Previews.self,
      size: CGSize(width: 400, height: 400)
    )
  }
}

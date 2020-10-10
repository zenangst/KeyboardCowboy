@testable import ViewKit
import XCTest

class SearchFieldTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: SearchField_Previews.self,
      size: CGSize(width: 300, height: 80)
    )
  }
}

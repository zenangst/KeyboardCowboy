@testable import ViewKit
import XCTest

class EditShellScriptViewTests: XCTestCase {
  func testSnapshotPreviews() {
    assertPreview(
      from: EditShellScriptView_Previews.self,
      size: CGSize(width: 600, height: 400)
    )
  }
}

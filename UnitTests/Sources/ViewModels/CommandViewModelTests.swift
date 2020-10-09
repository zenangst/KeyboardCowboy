import Foundation
@testable import ViewKit
import XCTest

class CommandViewModelKindTests: XCTestCase {
  func testKindApplicationId() {
    let subject = CommandViewModel.Kind.application(.empty())
    let expected = "application"

    XCTAssertEqual(subject.id, expected)
  }

  func testKindAppleScriptId() {
    let subject = CommandViewModel.Kind.appleScript(.empty())
    let expected = "appleScript"

    XCTAssertEqual(subject.id, expected)
  }

  func testKindKeyboardId() {
    let subject = CommandViewModel.Kind.keyboard(.empty())
    let expected = "keyboard"

    XCTAssertEqual(subject.id, expected)
  }

  func testKindOpenFileId() {
    let subject = CommandViewModel.Kind.openFile(.empty())
    let expected = "openFile"

    XCTAssertEqual(subject.id, expected)
  }

  func testKindOpenUrlId() {
    let subject = CommandViewModel.Kind.openUrl(.empty())
    let expected = "openUrl"

    XCTAssertEqual(subject.id, expected)
  }

  func testKindShellScriptId() {
    let subject = CommandViewModel.Kind.shellScript(.empty())
    let expected = "shellScript"

    XCTAssertEqual(subject.id, expected)
  }
}

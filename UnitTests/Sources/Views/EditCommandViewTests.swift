@testable import ViewKit
import XCTest
import ModelKit

// swiftlint:disable line_length
class EditCommandViewTests: XCTestCase {
  func testSnapshotApplication() {
    assertPreview(EditCommandView_Previews.display(model: Command.application(.init(application: Application.empty()))),
                  size: CGSize(width: 600, height: 400))
  }

  func testSnapshotAppleScript() {
    assertPreview(EditCommandView_Previews.display(model: Command.script(.appleScript(id: UUID().uuidString, name: nil, source: .path("path/to/applescript.scpt")))),
                  size: CGSize(width: 600, height: 400))
  }

  func testSnaphotShellScript() {
    assertPreview(EditCommandView_Previews.display(model: Command.script(.shell(id: UUID().uuidString, name: nil, source: .path("path/to/script.sh")))),
                  size: CGSize(width: 600, height: 400))
  }

  func testSnapshotKeyboard() {
    assertPreview(EditCommandView_Previews.display(model: Command.keyboard(KeyboardCommand(keyboardShortcut: KeyboardShortcut.empty()))),
                  size: CGSize(width: 600, height: 400))
  }

  func testSnapshotOpenUrl() {
    assertPreview(EditCommandView_Previews.display(model: Command.open(OpenCommand(path: "http://www.github.com"))),
                  size: CGSize(width: 600, height: 400))
  }

  func testSnapshotOpenFile() {
    assertPreview(EditCommandView_Previews.display(model: Command.open(OpenCommand.empty())),
                  size: CGSize(width: 600, height: 400))
  }

  func testSnapshotTypeCommand() {
    assertPreview(EditCommandView_Previews.display(model: Command.type(TypeCommand.init(name: "Type 'Hello world!'",
                                                                                        input: "Hello World!"))),
                  size: CGSize(width: 600, height: 400))
  }
}

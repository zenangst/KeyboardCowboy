import Foundation
import XCTest
import ViewKit
import LogicFramework
@testable import Keyboard_Cowboy

class CommandViewModelMapperTests: XCTestCase {
  let factory = ViewModelMapperFactory()

  // TODO: Enable mapping of inline scripts when we have UI support for it.
  func testMappingCommand() {
    let mapper = factory.commandMapper()
    let application: Application = .init(bundleIdentifier: "foo", bundleName: "bar", path: "baz")
    let identifier = UUID().uuidString
    let subject: [Command] = [
      .application(.init(id: identifier,
                         application: application)),
      .keyboard(.init(id: identifier,
                      keyboardShortcut: .init(
                        key: "F",
                        modifiers: [.command, .control, .function, .option, .shift]))),
      .open(.init(id: identifier, application: application, path: "/path/to/file")),
      .open(.init(id: identifier, application: application, path: "https://www.github.com")),
//      .script(.appleScript(.inline("script"), identifier)),
      .script(.appleScript(.path("path/to/script"), identifier)),
//      .script(.shell(.inline("script"), identifier)),
      .script(.shell(.path("path/to/script"), identifier))
    ]

    let applicationViewModel = ApplicationViewModel(id: identifier,
                                                    bundleIdentifier: application.bundleIdentifier,
                                                    name: application.bundleName,
                                                    path: application.path)

    let expected: [CommandViewModel] = [
      CommandViewModel(id: identifier, name: "bar", kind: .application(applicationViewModel)),

      CommandViewModel(id: identifier, name: "Run Keyboard Shortcut: ⌘⌃ƒ⌥⇧F", kind: .keyboard(
                        KeyboardShortcutViewModel(id: identifier, key: "F",
                                                  modifiers: [.command, .control, .function, .option, .shift]))),

      CommandViewModel(id: identifier, name: "/path/to/file",
                       kind: .openFile(OpenFileViewModel(id: identifier, path: "/path/to/file",
                                                         application: applicationViewModel))),

      CommandViewModel(id: identifier, name: "https://www.github.com",
                       kind: .openUrl(OpenURLViewModel(id: identifier, url: URL(string: "https://www.github.com")!,
                                                       application: applicationViewModel))),

//      CommandViewModel(id: identifier, name: "script", kind: .appleScript),

      CommandViewModel(id: identifier, name: "path/to/script",
                       kind: .appleScript(AppleScriptViewModel(id: identifier, path: "path/to/script"))),

//      CommandViewModel(id: identifier, name: "script", kind: .shellScript),

      CommandViewModel(id: identifier, name: "path/to/script",
                       kind: .shellScript(ShellScriptViewModel(id: identifier, path: "path/to/script")))
    ]

    let result = mapper.map(subject)

    XCTAssertEqual(result[0], expected[0])
    XCTAssertEqual(result[1], expected[1])
    XCTAssertEqual(result[2], expected[2])
    XCTAssertEqual(result[3], expected[3])
    XCTAssertEqual(result[4], expected[4])
    XCTAssertEqual(result[5], expected[5])
//    XCTAssertEqual(result[5], expected[5])
//    XCTAssertEqual(result[6], expected[6])
  }
}

import Foundation
import XCTest
import ViewKit
import LogicFramework
@testable import Keyboard_Cowboy

class CommandViewModelMapperTests: XCTestCase {
  let factory = ViewModelMapperFactory()

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
      .script(.appleScript(.inline("script"), identifier)),
      .script(.appleScript(.path("path/to/script"), identifier)),
      .script(.shell(.inline("script"), identifier)),
      .script(.shell(.path("path/to/script"), identifier))
    ]
    let expected: [CommandViewModel] = [
      CommandViewModel(id: identifier, name: "bar"),
      CommandViewModel(id: identifier, name: "F"),
      CommandViewModel(id: identifier, name: "/path/to/file"),
      CommandViewModel(id: identifier, name: "script"),
      CommandViewModel(id: identifier, name: "path/to/script"),
      CommandViewModel(id: identifier, name: "script"),
      CommandViewModel(id: identifier, name: "path/to/script")
    ]

    let result = mapper.map(subject)

    XCTAssertEqual(result[0], expected[0])
    XCTAssertEqual(result[1], expected[1])
    XCTAssertEqual(result[2], expected[2])
    XCTAssertEqual(result[3], expected[3])
    XCTAssertEqual(result[4], expected[4])
    XCTAssertEqual(result[5], expected[5])
    XCTAssertEqual(result[6], expected[6])
  }
}

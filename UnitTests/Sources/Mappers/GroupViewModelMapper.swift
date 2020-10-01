import Foundation
import XCTest
import ViewKit
import LogicFramework
@testable import Keyboard_Cowboy

class GroupViewModelMapperTests: XCTestCase {

  let factory = ViewModelMapperFactory()

  func testMappingGroupViewModel() {
    let mapper = factory.groupMapper()
    let application: Application = .init(bundleIdentifier: "foo", bundleName: "bar", path: "baz")
    let identifier = UUID().uuidString
    let subject = Group(id: identifier, name: "Test Group", color: "#000", rule: nil, workflows: [
      Workflow(
      id: identifier,
      commands: [
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
      ],
      keyboardShortcuts: [
        KeyboardShortcut(
          id: identifier,
          key: "A",
          modifiers: [.control, .option, .command])
      ],
      name: "Test workflow")
    ])

    let expected = GroupViewModel(id: identifier, name: "Test Group", color: "#000", workflows: [
      WorkflowViewModel(
        id: identifier,
        name: "Test workflow",
        keyboardShortcuts: [
          KeyboardShortcutViewModel(id: identifier, name: "⌃⌥⌘A")
        ],
        commands: [
          CommandViewModel(id: identifier, name: "bar", kind: .application(path: "baz", bundleIdentifier: "foo")),
          CommandViewModel(id: identifier, name: "F", kind: .keyboard),
          CommandViewModel(id: identifier, name: "/path/to/file",
                           kind: .openFile(path: "/path/to/file", application: "baz")),
          CommandViewModel(id: identifier, name: "script", kind: .appleScript),
          CommandViewModel(id: identifier, name: "path/to/script", kind: .appleScript),
          CommandViewModel(id: identifier, name: "script", kind: .shellScript),
          CommandViewModel(id: identifier, name: "path/to/script", kind: .shellScript)
        ])
    ])

    let result = mapper.map([subject])

    XCTAssertEqual([expected], result)

  }
}

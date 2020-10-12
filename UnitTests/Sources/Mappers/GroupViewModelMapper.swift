import Foundation
import XCTest
import ViewKit
import LogicFramework
@testable import Keyboard_Cowboy

class GroupViewModelMapperTests: XCTestCase {

  let factory = ViewModelMapperFactory()

  // swiftlint:disable function_body_length
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
//        .script(.appleScript(.inline("script"), identifier)),
        .script(.appleScript(.path("path/to/script"), identifier)),
//        .script(.shell(.inline("script"), identifier)),
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

    let applicationViewModel = ApplicationViewModel(id: identifier,
                                                    bundleIdentifier: application.bundleIdentifier,
                                                    name: application.bundleName,
                                                    path: application.path)

    let expected = GroupViewModel(id: identifier, name: "Test Group", color: "#000", workflows: [
      WorkflowViewModel(
        id: identifier,
        name: "Test workflow",
        keyboardShortcuts: [
          KeyboardShortcutViewModel(id: identifier, index: 1, key: "A", modifiers: [.control, .option, .command])
        ],
        commands: [
          CommandViewModel(id: identifier, name: "bar", kind: .application(applicationViewModel)),

          CommandViewModel(id: identifier, name: "Run Keyboard Shortcut: ⌘⌃ƒ⌥⇧F", kind: .keyboard(
                            KeyboardShortcutViewModel(id: identifier, index: 0, key: "F",
                                                      modifiers: [.command, .control, .function, .option, .shift]))),

          CommandViewModel(id: identifier, name: "/path/to/file",
                           kind: .openFile(OpenFileViewModel(id: identifier, path: "/path/to/file",
                                                             application: applicationViewModel))),

    //      CommandViewModel(id: identifier, name: "script", kind: .appleScript),

          CommandViewModel(id: identifier, name: "path/to/script",
                           kind: .appleScript(AppleScriptViewModel(id: identifier, path: "path/to/script"))),

    //      CommandViewModel(id: identifier, name: "script", kind: .shellScript),

          CommandViewModel(id: identifier, name: "path/to/script",
                           kind: .shellScript(ShellScriptViewModel(id: identifier, path: "path/to/script")))
        ])
    ])

    let result = mapper.map([subject])

    XCTAssertEqual(expected.workflows[0].name, result[0].workflows[0].name)
    XCTAssertEqual(expected.workflows[0].commands, result[0].workflows[0].commands)
    XCTAssertEqual(expected.workflows[0].commands[0], result[0].workflows[0].commands[0])
    XCTAssertEqual(expected.workflows[0].commands[1], result[0].workflows[0].commands[1])
    XCTAssertEqual(expected.workflows[0].commands[2], result[0].workflows[0].commands[2])
    XCTAssertEqual(expected.workflows[0].commands[3], result[0].workflows[0].commands[3])
    XCTAssertEqual(expected.workflows[0].commands[4], result[0].workflows[0].commands[4])
    XCTAssertEqual(expected.workflows[0].keyboardShortcuts, result[0].workflows[0].keyboardShortcuts)

  }
}

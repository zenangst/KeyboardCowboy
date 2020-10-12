import Foundation
import XCTest
import ViewKit
import LogicFramework
@testable import Keyboard_Cowboy

// swiftlint:disable function_body_length
class WorkflowViewModelMapperTests: XCTestCase {

  let factory = ViewModelMapperFactory()

  func testMappingWorkflowViewModel() {
    let mapper = factory.workflowMapper()
    let application: Application = .init(bundleIdentifier: "foo", bundleName: "bar", path: "baz")
    let identifier = UUID().uuidString
    let subject = Workflow(
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

    let applicationViewModel = ApplicationViewModel(id: identifier,
                                                    bundleIdentifier: application.bundleIdentifier,
                                                    name: application.bundleName,
                                                    path: application.path)

    let expected = WorkflowViewModel(
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

//        CommandViewModel(id: identifier, name: "script", kind: .appleScript),

        CommandViewModel(id: identifier, name: "path/to/script",
                         kind: .appleScript(AppleScriptViewModel(id: identifier, path: "path/to/script"))),

  //      CommandViewModel(id: identifier, name: "script", kind: .shellScript),

        CommandViewModel(id: identifier, name: "path/to/script",
                         kind: .shellScript(ShellScriptViewModel(id: identifier, path: "path/to/script")))
      ])

    let result = mapper.map([subject])

    XCTAssertEqual(expected.commands[0], result[0].commands[0])
    XCTAssertEqual(expected.commands[1], result[0].commands[1])
    XCTAssertEqual(expected.commands[2], result[0].commands[2])
    XCTAssertEqual(expected.commands[3], result[0].commands[3])
    XCTAssertEqual(expected.commands[4], result[0].commands[4])

  }
}

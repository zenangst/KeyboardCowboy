@testable import Keyboard_Cowboy
import XCTest

final class WorkflowTests: XCTestCase {
  func testCopy() {
    let subject = Workflow.designTime(.application([.init(application: .calendar())]))
    let copy = subject.copy()

    XCTAssertNotEqual(subject.id, copy.id)
    XCTAssertEqual(subject.name, copy.name)
    XCTAssertEqual(subject.isEnabled, copy.isEnabled)

    switch (subject.trigger, copy.trigger) {
    case (.application(let lhs), .application(let rhs)):
      XCTAssertEqual(lhs.count, rhs.count)
      for x in 0..<lhs.count {
        XCTAssertNotEqual(lhs[x].id, rhs[x].id)
        XCTAssertEqual(lhs[x].contexts, rhs[x].contexts)
        XCTAssertEqual(lhs[x].application, rhs[x].application)
      }
    default:
      XCTFail("Wrong case!")
    }

    XCTAssertEqual(subject.execution, copy.execution)

    for x in 0..<subject.commands.count {
      XCTAssertNotEqual(subject.commands[x].id, copy.commands[x].id)
      XCTAssertEqual(subject.commands[x].name, copy.commands[x].name)
    }
  }

  func testShouldResolveDocumentAndSelectionsForApplication() {
    let workflow = Workflow.designTime(.application([.init(application: .calendar())]))
    let shouldResolve = workflow.shouldResolveDocumentAndSelections()
    XCTAssertFalse(shouldResolve, "Application command workflows should not resolve document and selections.")
  }

  func testShouldResolveDocumentAndSelectionsForBuiltInCommands() {
    let workflow = Workflow(
      name: "Built-in command",
      commands: [.builtIn(
        .init(kind: .userMode(.init(id: UUID().uuidString, name: UUID().uuidString, isEnabled: true), .toggle), notification: false
        )
      )]
    )
    let shouldResolve = workflow.shouldResolveDocumentAndSelections()
    XCTAssertFalse(shouldResolve, "Built-in command workflows should not resolve document and selections.")
  }

  func testShouldResolveDocumentAndSelectionsForMouseCommands() {
    let workflow = Workflow(
      name: "Mouse",
      commands: [.mouse(.init(meta: .init(), kind: .click(.focused(.center))))]
    )
    let shouldResolve = workflow.shouldResolveDocumentAndSelections()
    XCTAssertFalse(shouldResolve, "Mouse command workflows should not resolve document and selections.")
  }

  func testShouldResolveDocumentAndSelectionForKeyboardCommands() {
    let workflow = Workflow(
      name: "Keyboard Shortcut",
      commands: [.keyboard(.empty())]
    )
    let shouldResolve = workflow.shouldResolveDocumentAndSelections()
    XCTAssertFalse(shouldResolve, "Keyboard shortcut command workflows should resolve document and selections.")
  }

  func testShouldResolveDocumentAndSelectionForMenuBarCommands() {
    let workflow = Workflow(
      name: "Menu bar",
      commands: [.menuBar(.init(tokens: [.menuItem(name: "Test")]))]
    )
    let shouldResolve = workflow.shouldResolveDocumentAndSelections()
    XCTAssertFalse(shouldResolve, "Menu bar command workflows should not resolve document and selections.")
  }

  func testShouldResolveDocumentAndSelectionForShortcutCommands() {
    let workflow = Workflow(
      name: "Shortcut",
      commands: [.shortcut(.init(id: "", shortcutIdentifier: "", name: "", isEnabled: false, notification: false))])
    let shouldResolve = workflow.shouldResolveDocumentAndSelections()
    XCTAssertFalse(shouldResolve, "Shortcut command workflows should not resolve document and selections.")
  }

  func testShouldResolveDocumentAndSelectionForSystemCommand() {
    let workflow = Workflow(
      name: "System",
      commands: [.systemCommand(.init(name: "", kind: .activateLastApplication, notification: false))])
    let shouldResolve = workflow.shouldResolveDocumentAndSelections()
    XCTAssertFalse(shouldResolve, "System command workflows should not resolve document and selections.")
  }

  func testShouldResolveDocumentAndSelectionForWindowManagement() {
    let workflow = Workflow(
      name: "Window management",
      commands: [.windowManagement(.init(id: "", name: "", kind: .center, notification: false, animationDuration: 0.0))]
    )
    let shouldResolve = workflow.shouldResolveDocumentAndSelections()
    XCTAssertFalse(shouldResolve, "Window management command workflows should not resolve document and selections.")
  }

  func testShouldResolveDocumentAndSelectionForOpenCommand_path() {
    do {
      // Empty open command
      let workflow = Workflow(
        name: "Open",
        commands: [.open(.init(id: "", name: "", path: "", notification: false))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertFalse(shouldResolve, "Open commands with empty paths should not resolve document and selections.")
    }

    do {
      // With a random path
      let workflow = Workflow(
        name: "Open",
        commands: [.open(.init(id: "", name: "", path: UUID().uuidString, notification: false))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertFalse(shouldResolve, "Open commands with random paths that don't inclue valid env keys should not resolve document and selections.")
    }

    do {
      // With an invalid env key
      let workflow = Workflow(
        name: "Open",
        commands: [.open(.init(id: "", name: "", path: UserSpace.EnvironmentKey.directory.rawValue, notification: false))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertFalse(shouldResolve, "Open commands with invalid env keys should not resolve document and selections.")
    }

    do {
      // With an valid env key
      let workflow = Workflow(
        name: "Open",
        commands: [.open(.init(id: "", name: "", path: UserSpace.EnvironmentKey.directory.asTextVariable, notification: false))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertTrue(shouldResolve, "Open commands with valid env keys should resolve document and selections.")
    }
  }

  func testShouldResolveDocumentAndSelectionForScriptCommand_inline() {
    do {
      // Empty apple script
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript, source: .inline(""), notification: false))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertFalse(shouldResolve, "Script commands with empty apple scripts should not resolve document and selections.")
    }

    do {
      // With an invalid env key
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript, source: .inline(UserSpace.EnvironmentKey.selectedText.rawValue), notification: false))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertFalse(shouldResolve, "Script commands with invalid env keys should not resolve document and selections.")
    }

    do {
      // With an valid env key
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript, source: .inline(UserSpace.EnvironmentKey.selectedText.asTextVariable), notification: false))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertTrue(shouldResolve, "Script commands with valid env keys should resolve document and selections.")
    }
  }

  func testShouldResolveDocumentAndSelectionForScriptCommand_path() {
    do {
      // Empty apple script
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript, source: .path(""), notification: false))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertFalse(shouldResolve, "Script commands with empty paths apple scripts should not resolve document and selections.")
    }

    do {
      // With an invalid env key
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript, source: .path(UserSpace.EnvironmentKey.selectedText.rawValue), notification: false))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertFalse(shouldResolve, "Script commands with invalid env keys should not resolve document and selections.")
    }

    do {
      // With an valid env key
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript, source: .path(UserSpace.EnvironmentKey.selectedText.asTextVariable), notification: false))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertTrue(shouldResolve, "Script commands with valid env keys should resolve document and selections.")
    }
  }

  func testShouldResolveDocumentAndSelectionForTextCommand() {
    do {
      let workflow = Workflow(
        name: "Text",
        commands: [.text(.init(.insertText(.init("", mode: .instant))))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertFalse(shouldResolve, "Empty text commands should not resolve document and selections.")
    }

    do {
      let workflow = Workflow(
        name: "Text",
        commands: [.text(.init(.insertText(.init(UUID().uuidString, mode: .instant))))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertFalse(shouldResolve, "Text commands without env keys should not resolve document and selections.")
    }

    do {
      let workflow = Workflow(
        name: "Text",
        commands: [.text(.init(.insertText(.init(UserSpace.EnvironmentKey.selectedText.rawValue, mode: .instant))))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertFalse(shouldResolve, "Text commands with invalid env keys should not resolve document and selections.")
    }

    do {
      let workflow = Workflow(
        name: "Text",
        commands: [.text(.init(.insertText(.init(UserSpace.EnvironmentKey.selectedText.asTextVariable, mode: .instant))))]
      )
      let shouldResolve = workflow.shouldResolveDocumentAndSelections()
      XCTAssertTrue(shouldResolve, "Text commands with valid env keys should not resolve document and selections.")
    }
  }
}

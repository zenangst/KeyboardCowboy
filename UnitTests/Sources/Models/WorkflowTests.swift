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
    case let (.application(lhs), .application(rhs)):
      XCTAssertEqual(lhs.count, rhs.count)
      for x in 0 ..< lhs.count {
        XCTAssertNotEqual(lhs[x].id, rhs[x].id)
        XCTAssertEqual(lhs[x].contexts, rhs[x].contexts)
        XCTAssertEqual(lhs[x].application, rhs[x].application)
      }
    default:
      XCTFail("Wrong case!")
    }

    XCTAssertEqual(subject.execution, copy.execution)

    for x in 0 ..< subject.commands.count {
      XCTAssertNotEqual(subject.commands[x].id, copy.commands[x].id)
      XCTAssertEqual(subject.commands[x].name, copy.commands[x].name)
    }
  }

  func testResolveUserEnvironmentForApplication() {
    let workflow = Workflow.designTime(.application([.init(application: .calendar())]))
    let shouldResolve = workflow.resolveUserEnvironment()
    XCTAssertFalse(shouldResolve, "Application command workflows should not resolve user environment.")
  }

  func testResolveUserEnvironmentForBuiltInCommands() {
    let workflow = Workflow(
      name: "Built-in command",
      commands: [.builtIn(
        .init(kind: .userMode(mode: .init(id: UUID().uuidString, name: UUID().uuidString, isEnabled: true), action: .toggle), notification: nil),
      )],
    )
    let shouldResolve = workflow.resolveUserEnvironment()
    XCTAssertFalse(shouldResolve, "Built-in command workflows should not resolve user environment.")
  }

  func testResolveUserEnvironmentForMouseCommands() {
    let workflow = Workflow(
      name: "Mouse",
      commands: [.mouse(.init(meta: .init(), kind: .click(.focused(.center))))],
    )
    let shouldResolve = workflow.resolveUserEnvironment()
    XCTAssertFalse(shouldResolve, "Mouse command workflows should not resolve user environment.")
  }

  func testResolveUserEnvironmentForKeyboardCommands() {
    let workflow = Workflow(
      name: "Keyboard Shortcut",
      commands: [.keyboard(.empty())],
    )
    let shouldResolve = workflow.resolveUserEnvironment()
    XCTAssertFalse(shouldResolve, "Keyboard shortcut command workflows should resolve user environment.")
  }

  func testResolveUserEnvironmentForMenuBarCommands() {
    let workflow = Workflow(
      name: "Menu bar",
      commands: [.menuBar(
        .init(application: nil, tokens: [.menuItem(name: "Test")]),
      )],
    )
    let shouldResolve = workflow.resolveUserEnvironment()
    XCTAssertFalse(shouldResolve, "Menu bar command workflows should not resolve user environment.")
  }

  func testResolveUserEnvironmentForShortcutCommands() {
    let workflow = Workflow(
      name: "Shortcut",
      commands: [.shortcut(.init(id: "", shortcutIdentifier: "", name: "", isEnabled: false, notification: nil))],
    )
    let shouldResolve = workflow.resolveUserEnvironment()
    XCTAssertFalse(shouldResolve, "Shortcut command workflows should not resolve user environment.")
  }

  func testResolveUserEnvironmentForSystemCommand() {
    let workflow = Workflow(
      name: "System",
      commands: [.systemCommand(.init(name: "", kind: .activateLastApplication, notification: nil))],
    )
    let shouldResolve = workflow.resolveUserEnvironment()
    XCTAssertFalse(shouldResolve, "System command workflows should not resolve user environment.")
  }

  func testResolveUserEnvironmentForWindowManagement() {
    let workflow = Workflow(
      name: "Window management",
      commands: [.windowManagement(.init(id: "", name: "", kind: .center, notification: nil, animationDuration: 0.0))],
    )
    let shouldResolve = workflow.resolveUserEnvironment()
    XCTAssertFalse(shouldResolve, "Window management command workflows should not resolve user environment.")
  }

  func testResolveUserEnvironmentForOpenCommand_path() {
    do {
      // Empty open command
      let workflow = Workflow(
        name: "Open",
        commands: [.open(.init(id: "", name: "", path: "", notification: nil))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertFalse(shouldResolve, "Open commands with empty paths should not resolve user environment.")
    }

    do {
      // With a random path
      let workflow = Workflow(
        name: "Open",
        commands: [.open(.init(id: "", name: "", path: UUID().uuidString, notification: nil))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertFalse(shouldResolve, "Open commands with random paths that don't inclue valid env keys should not resolve document and selections.")
    }

    do {
      // With an invalid env key
      let workflow = Workflow(
        name: "Open",
        commands: [.open(.init(id: "", name: "", path: UserSpace.EnvironmentKey.directory.rawValue, notification: nil))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertFalse(shouldResolve, "Open commands with invalid env keys should not resolve document and selections.")
    }

    do {
      // With an valid env key
      let workflow = Workflow(
        name: "Open",
        commands: [.open(.init(id: "", name: "", path: UserSpace.EnvironmentKey.directory.asTextVariable, notification: nil))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertTrue(shouldResolve, "Open commands with valid env keys should resolve document and selections.")
    }
  }

  func testResolveUserEnvironmentForScriptCommand_inline() {
    do {
      // Empty apple script
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript(variant: .regular), source: .inline(""), notification: nil))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertFalse(shouldResolve, "Script commands with empty apple scripts should not resolve user environment.")
    }

    do {
      // With an invalid env key
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript(variant: .regular), source: .inline(UserSpace.EnvironmentKey.selectedText.rawValue), notification: nil))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertFalse(shouldResolve, "Script commands with invalid env keys should not resolve user environment.")
    }

    do {
      // With an valid env key
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript(variant: .regular), source: .inline(UserSpace.EnvironmentKey.selectedText.asTextVariable), notification: nil))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertTrue(shouldResolve, "Script commands with valid env keys should resolve user environment.")
    }
  }

  func testResolveUserEnvironmentForScriptCommand_path() {
    do {
      // Empty apple script
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript(variant: .regular), source: .path(""), notification: nil))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertFalse(shouldResolve, "Script commands with empty paths apple scripts should not resolve user environment.")
    }

    do {
      // With an invalid env key
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript(variant: .regular), source: .path(UserSpace.EnvironmentKey.selectedText.rawValue), notification: nil))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertFalse(shouldResolve, "Script commands with invalid env keys should not resolve user environment.")
    }

    do {
      // With an valid env key
      let workflow = Workflow(
        name: "Script",
        commands: [.script(.init(name: "", kind: .appleScript(variant: .regular), source: .path(UserSpace.EnvironmentKey.selectedText.asTextVariable), notification: nil))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertTrue(shouldResolve, "Script commands with valid env keys should resolve user environment.")
    }
  }

  func testResolveUserEnvironmentForTextCommand() {
    do {
      let workflow = Workflow(
        name: "Text",
        commands: [.text(.init(.insertText(.init("", mode: .instant, actions: []))))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertFalse(shouldResolve, "Empty text commands should not resolve user environment.")
    }

    do {
      let workflow = Workflow(
        name: "Text",
        commands: [.text(.init(.insertText(.init(UUID().uuidString, mode: .instant, actions: []))))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertFalse(shouldResolve, "Text commands without env keys should not resolve user environment.")
    }

    do {
      let workflow = Workflow(
        name: "Text",
        commands: [.text(.init(.insertText(.init(UserSpace.EnvironmentKey.selectedText.rawValue, mode: .instant, actions: []))))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertFalse(shouldResolve, "Text commands with invalid env keys should not resolve user environment.")
    }

    do {
      let workflow = Workflow(
        name: "Text",
        commands: [.text(.init(.insertText(.init(UserSpace.EnvironmentKey.selectedText.asTextVariable, mode: .instant, actions: []))))],
      )
      let shouldResolve = workflow.resolveUserEnvironment()
      XCTAssertTrue(shouldResolve, "Text commands with valid env keys should not resolve user environment.")
    }
  }
}

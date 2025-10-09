@testable import Keyboard_Cowboy
import XCTest

final class KeyboardCowboyConfigurationCommandTests: XCTestCase {
  static let config = KeyboardCowboyConfiguration(
    name: "test",
    userModes: [],
    groups: [
      WorkflowGroup(
        id: "group-1",
        name: "group-1",
        workflows: [
          Workflow(
            id: "workflow-1",
            name: "workflow-1",
            commands: [
              Command.openCommand(id: "command-1"),
              Command.openCommand(id: "command-2"),
              Command.openCommand(id: "command-3"),
            ],
          ),

          Workflow(
            id: "workflow-2",
            name: "workflow-2",
            commands: [
              Command.openCommand(id: "command-4"),
              Command.openCommand(id: "command-5"),
              Command.openCommand(id: "command-6"),
            ],
          ),
          Workflow(
            id: "workflow-3",
            name: "workflow-3",
            commands: [
              Command.openCommand(id: "command-7"),
              Command.openCommand(id: "command-8"),
              Command.openCommand(id: "command-9"),
            ],
          ),
          Workflow(
            id: "workflow-4",
            name: "workflow-4",
            commands: [],
          ),
        ],
      ),
      WorkflowGroup(name: "group 2"),
    ],
  )
  func testUpdate() {
    var config = Self.config

    XCTAssertFalse(config.update(groupID: "unknown-group", workflowID: "workflow-2", commandID: "command-5", keyPath: \.name, newValue: "new name"))
    XCTAssertTrue(config.update(groupID: "group-1", workflowID: "workflow-2", commandID: "command-5", keyPath: \.name, newValue: "new name"))
    XCTAssertEqual(config.groups[0].workflows[1].commands[1].name, "new name")
  }

  func testModify() {
    var config = Self.config

    let failure = config.modify(groupID: "unknown-group", workflowID: "workflow-2", commandID: "command-5") { _ in
      XCTFail("Should not end up here")
    }

    let success = config.modify(groupID: "group-1", workflowID: "workflow-2", commandID: "command-5") {
      $0.id = "foo-id"
      $0.name = "foo"
    }

    XCTAssertFalse(failure)
    XCTAssertTrue(success)
    XCTAssertEqual(config.groups[0].workflows[1].commands[1].id, "foo-id")
    XCTAssertEqual(config.groups[0].workflows[1].commands[1].name, "foo")
  }

  func testReplace() {
    var config = Self.config
    let newCommand = Command.textCommand(id: "text-id")
    XCTAssertFalse(config.replace(groupID: "unknown-group", workflowID: "workflow-2", commandID: "command-5", command: newCommand))
    XCTAssertTrue(config.replace(groupID: "group-1", workflowID: "workflow-2", commandID: "command-5", command: newCommand))
    XCTAssertEqual(config.groups[0].workflows[1].commands[1].id, "text-id")
  }

  func testAppend() {
    var config = Self.config
    XCTAssertFalse(config.append(groupID: "unknown-group", workflowID: "workflow-2", command: Command.textCommand(id: "text-id")))
    XCTAssertTrue(config.append(groupID: "group-1", workflowID: "workflow-2", command: Command.textCommand(id: "text-id")))
    XCTAssertEqual(config.groups[0].workflows[1].commands.map(\.id), ["command-4", "command-5", "command-6", "text-id"])
  }

  func testInsert() {
    var config = Self.config
    XCTAssertFalse(config.insert(groupID: "unknown-group", workflowID: "workflow-2", command: Command.textCommand(id: "-1"), at: 0))

    XCTAssertTrue(config.insert(groupID: "group-1", workflowID: "workflow-2", command: Command.textCommand(id: "-1"), at: -1))
    XCTAssertEqual(config.groups[0].workflows[1].commands.map(\.id), ["-1", "command-4", "command-5", "command-6"])

    XCTAssertTrue(config.insert(groupID: "group-1", workflowID: "workflow-2", command: Command.textCommand(id: "0"), at: 0))
    XCTAssertEqual(config.groups[0].workflows[1].commands.map(\.id), ["0", "-1", "command-4", "command-5", "command-6"])

    XCTAssertTrue(config.insert(groupID: "group-1", workflowID: "workflow-2", command: Command.textCommand(id: "3"), at: 3))
    XCTAssertEqual(config.groups[0].workflows[1].commands.map(\.id), ["0", "-1", "command-4", "3", "command-5", "command-6"])

    XCTAssertTrue(config.insert(groupID: "group-1", workflowID: "workflow-2", command: Command.textCommand(id: "100"), at: 100))
    XCTAssertEqual(config.groups[0].workflows[1].commands.map(\.id), ["0", "-1", "command-4", "3", "command-5", "command-6", "100"])

    XCTAssertTrue(config.groups[0].workflows[3].commands.isEmpty)
    XCTAssertTrue(config.insert(groupID: "group-1", workflowID: "workflow-4", command: Command.textCommand(id: "100"), at: 100))
    XCTAssertEqual(config.groups[0].workflows[3].commands.map(\.id), ["100"])
  }
}

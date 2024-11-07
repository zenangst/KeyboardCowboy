@testable import Keyboard_Cowboy
import XCTest

final class KeyboardCowboyConfigurationWorkflowTests: XCTestCase {
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
            ]
          ),

          Workflow(
            id: "workflow-2",
            name: "workflow-2",
            commands: [
              Command.openCommand(id: "command-4"),
              Command.openCommand(id: "command-5"),
              Command.openCommand(id: "command-6"),
            ]
          ),
          Workflow(
            id: "workflow-3",
            name: "workflow-3",
            commands: [
              Command.openCommand(id: "command-7"),
              Command.openCommand(id: "command-8"),
              Command.openCommand(id: "command-9"),
            ]
          ),
          Workflow(
            id: "workflow-4",
            name: "workflow-4",
            commands: [ ]
          )
        ]
      ),
      WorkflowGroup(id: "group-2", name: "group-2"),
    ]
  )
  func testUpdate() {
    var config = Self.config

    XCTAssertFalse(config.update(groupID: "unknown-group", workflowID: "workflow-1", keyPath: \Workflow.name, newValue: "updated-workflow"))
    XCTAssertTrue(config.update(groupID: "group-1", workflowID: "workflow-1", keyPath: \Workflow.name, newValue: "updated-workflow"))
    XCTAssertEqual(config.groups.flatMap { $0.workflows }.map(\.name), ["updated-workflow", "workflow-2", "workflow-3", "workflow-4"])
  }

  func testModify() {
    var config = Self.config
    XCTAssertFalse(config.modify(groupID: "unknown-group", workflowID: "workflow-1") { _ in XCTFail("unknown group") })
    XCTAssertTrue(config.modify(groupID: "group-1", workflowID: "workflow-1") { $0.name = "updated-workflow" })
    XCTAssertEqual(config.groups.flatMap { $0.workflows }.map(\.name), ["updated-workflow", "workflow-2", "workflow-3", "workflow-4"])
  }

  func testReplace() {
    var config = Self.config

    let newWorkflow = Workflow(name: "new-workflow")
    XCTAssertFalse(config.replace(groupID: "unknown-group", workflowID: "workflow-1", workflow: newWorkflow))
    XCTAssertTrue(config.replace(groupID: "group-1", workflowID: "workflow-2", workflow: newWorkflow))
    XCTAssertEqual(config.groups.flatMap { $0.workflows }.map(\.name), ["workflow-1", "new-workflow", "workflow-3", "workflow-4"])
  }

  func testAppend() {
    var config = Self.config
    XCTAssertFalse(config.append(groupID: "unknown-group", workflow: Workflow(name: "new-workflow")))
    XCTAssertTrue(config.append(groupID: "group-1", workflow: Workflow(name: "new-workflow")))
    XCTAssertEqual(config.groups.flatMap { $0.workflows }.map(\.name), ["workflow-1", "workflow-2", "workflow-3", "workflow-4", "new-workflow"])
  }

  func testInsert() {
    var config = Self.config

    XCTAssertFalse(config.insert(groupID: "unknown-group", workflow: Workflow(name: "-1"), at: -1))
    XCTAssertTrue(config.insert(groupID: "group-1", workflow: Workflow(name: "-1"), at: -1))
    XCTAssertEqual(config.groups.flatMap { $0.workflows }.map(\.name), ["-1", "workflow-1", "workflow-2", "workflow-3", "workflow-4"])
    XCTAssertTrue(config.insert(groupID: "group-1", workflow: Workflow(name: "0"), at: 0))
    XCTAssertEqual(config.groups.flatMap { $0.workflows }.map(\.name), ["0", "-1", "workflow-1", "workflow-2", "workflow-3", "workflow-4"])
    XCTAssertTrue(config.insert(groupID: "group-1", workflow: Workflow(name: "100"), at: 100))
    XCTAssertEqual(config.groups.flatMap { $0.workflows }.map(\.name), ["0", "-1", "workflow-1", "workflow-2", "workflow-3", "workflow-4", "100"])

    XCTAssertTrue(config.insert(groupID: "group-2", workflow: Workflow(name: "100"), at: 100))
    XCTAssertEqual(config.groups[1].workflows.map(\.name), ["100"])
  }
}

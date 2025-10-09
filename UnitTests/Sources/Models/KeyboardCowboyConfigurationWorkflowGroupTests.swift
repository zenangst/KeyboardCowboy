@testable import Keyboard_Cowboy
import XCTest

final class KeyboardCowboyConfigurationWorkflowGroupTests: XCTestCase {
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
        ],
      ),
      WorkflowGroup(name: "group-2"),
    ],
  )
  func testUpdate() {
    var config = Self.config
    XCTAssertFalse(config.update(groupID: "unknown-group", keyPath: \WorkflowGroup.name, newValue: "new group"))
    XCTAssertTrue(config.update(groupID: "group-1", keyPath: \WorkflowGroup.name, newValue: "group-update"))
    XCTAssertEqual(config.groups[0].name, "group-update")
  }

  func testModify() {
    var config = Self.config
    XCTAssertFalse(config.modify(groupID: "unknown-group", modify: { $0.name = "group-update" }))
    XCTAssertTrue(config.modify(groupID: "group-1", modify: { $0.name = "group-update" }))
    XCTAssertEqual(config.groups[0].name, "group-update")
  }

  func testReplace() {
    var config = Self.config
    let group = WorkflowGroup(name: "new-group")
    XCTAssertFalse(config.replace(groupID: "unknown-group", group: group))
    XCTAssertTrue(config.replace(groupID: "group-1", group: group))
    XCTAssertEqual(config.groups[0], group)
  }

  func testInsert() {
    var config = Self.config
    XCTAssertEqual(config.groups.map(\.name), ["group-1", "group-2"])
    XCTAssertTrue(config.insert(group: WorkflowGroup(name: "-1"), at: -1))
    XCTAssertEqual(config.groups.map(\.name), ["-1", "group-1", "group-2"])
    XCTAssertTrue(config.insert(group: WorkflowGroup(name: "0"), at: -1))
    XCTAssertEqual(config.groups.map(\.name), ["0", "-1", "group-1", "group-2"])
    XCTAssertTrue(config.insert(group: WorkflowGroup(name: "100"), at: 100))
    XCTAssertEqual(config.groups.map(\.name), ["0", "-1", "group-1", "group-2", "100"])

    config.groups.removeAll()

    XCTAssertTrue(config.insert(group: WorkflowGroup(name: "100"), at: 100))
    XCTAssertEqual(config.groups.map(\.name), ["100"])
  }
}

@testable import Keyboard_Cowboy
@testable import LogicFramework
@testable import ModelKit
@testable import ViewKit
import Foundation
import ModelKit
import XCTest

// swiftlint:disable function_body_length type_body_length
class CommandsFeatureControllerTests: XCTestCase {
  func testCreateCommand() {
    let expectation = self.expectation(description: "Wait for callback")
    var group = Group.empty()
    let workflow = Workflow.empty()
    group.workflows = [workflow]

    let command = Command.application(.init(application: Application.finder()))
    let commandController = CommandControllerMock()
    let groupsController = GroupsController(groups: [group])
    let coreController = CoreControllerMock(commandController: commandController,
                                            groupsController: groupsController) { state in
      switch state {
      case .respondTo,
           .reloadContext,
           .activate:
        XCTFail("Wrong state, should end up in `.didReloadGroups`")
      case .didReloadGroups(let groups):
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groupsController.groups.count, 1)
        XCTAssertEqual(groups, groupsController.groups)

        guard let group = groups.first else {
          XCTFail("Failed to find first group.")
          return
        }

        XCTAssertEqual(group.workflows.count, 1)

        guard let workflow = group.workflows.first else {
          XCTFail("Failed to find first workflow.")
          return
        }

        XCTAssertEqual(workflow.commands.count, 1)

        guard let newCommand = workflow.commands.first else {
          XCTFail("Failed to find first workflow.")
          return
        }

        XCTAssertEqual(newCommand, command)
        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController)
    let groupsFeature = factory.groupFeature(userSelection: userSelection)
    let workflowFeature = factory.workflowFeature()
    let commandsFeature = factory.commandsFeature(commandController: commandController)

    userSelection.group = group
    userSelection.workflow = workflow
    workflowFeature.delegate = groupsFeature
    commandsFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap({ $0.workflows }).count, 1)

    commandsFeature.perform(.createCommand(command, in: workflow))

    wait(for: [expectation], timeout: 10.0)
  }

  func testUpdateCommand() {
    let expectation = self.expectation(description: "Wait for callback")
    let command = Command.application(.init(application: .finder()))
    var group = Group.empty()
    var workflow = Workflow.empty()
    workflow.commands = [command]
    group.workflows = [workflow]

    let commandIdentifier = UUID().uuidString
    let newKeyboardCommand = KeyboardCommand(
      id: command.id,
      keyboardShortcut: KeyboardShortcut(
        id: commandIdentifier,
        key: "A",
        modifiers: [.command]))
    let updatedCommand = Command.keyboard(newKeyboardCommand)

    let groupsController = GroupsController(groups: [group])
    let commandController = CommandControllerMock()
    let coreController = CoreControllerMock(commandController: commandController,
                                            groupsController: groupsController) { state in
      switch state {
      case .respondTo,
           .reloadContext,
           .activate:
        XCTFail("Wrong state, should end up in `.didReloadGroups`")
      case .didReloadGroups(let groups):
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groupsController.groups.count, 1)
        XCTAssertEqual(groups, groupsController.groups)

        guard let group = groups.first else {
          XCTFail("Failed to find first group.")
          return
        }

        XCTAssertEqual(group.workflows.count, 1)

        guard let workflow = group.workflows.first else {
          XCTFail("Failed to find first workflow.")
          return
        }

        XCTAssertEqual(workflow.commands.count, 1)

        guard let newCommand = workflow.commands.first else {
          XCTFail("Failed to find first workflow.")
          return
        }

        switch newCommand {
        case .keyboard(let keyboardCommand):
          XCTAssertEqual(newCommand.id, updatedCommand.id)
          XCTAssertEqual(keyboardCommand.keyboardShortcut.key, newKeyboardCommand.keyboardShortcut.key)
          XCTAssertEqual(keyboardCommand.keyboardShortcut.modifiers, newKeyboardCommand.keyboardShortcut.modifiers)
        case .application, .open, .script:
          XCTFail("Wrong command kind. Should be `.application`")
        }

        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController)
    let groupsFeature = factory.groupFeature(userSelection: userSelection)
    let workflowFeature = factory.workflowFeature()
    let commandsFeature = factory.commandsFeature(commandController: commandController)

    userSelection.group = group
    userSelection.workflow = workflow
    workflowFeature.delegate = groupsFeature
    commandsFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap({ $0.workflows }).count, 1)

    commandsFeature.perform(.updateCommand(updatedCommand, in: workflow))

    wait(for: [expectation], timeout: 10.0)
  }

  func testMoveCommand() {
    let expectation = self.expectation(description: "Wait for callback")
    let identifier = UUID().uuidString
    let command: Command = .open(.init(id: identifier, path: "path/to/file"))
    let commands: [Command] = [
      .script(.appleScript(.path("path"), "appleScript")),
      .script(.shell(.path("path"), "shellScript")),
      command
    ]
    let expected: [Command] = [
      command,
      .script(.appleScript(.path("path"), "appleScript")),
      .script(.shell(.path("path"), "shellScript"))
    ]
    var group = Group.empty()
    var workflow = Workflow.empty()
    workflow.commands = commands
    group.workflows = [workflow]

    let groupsController = GroupsController(groups: [group])
    let commandController = CommandControllerMock()
    let coreController = CoreControllerMock(commandController: commandController,
                                            groupsController: groupsController) { state in
      switch state {
      case .respondTo,
           .reloadContext,
           .activate:
        XCTFail("Wrong state, should end up in `.didReloadGroups`")
      case .didReloadGroups(let groups):
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groupsController.groups.count, 1)
        XCTAssertEqual(groups, groupsController.groups)

        guard let group = groups.first else {
          XCTFail("Failed to find first group.")
          return
        }

        XCTAssertEqual(group.workflows.count, 1)

        guard let workflow = group.workflows.first else {
          XCTFail("Failed to find first workflow.")
          return
        }

        XCTAssertEqual(workflow.commands.count, 3)
        XCTAssertEqual(expected, workflow.commands)

        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController)
    let groupsFeature = factory.groupFeature(userSelection: userSelection)
    let workflowFeature = factory.workflowFeature()
    let commandsFeature = factory.commandsFeature(commandController: commandController)

    userSelection.group = group
    userSelection.workflow = workflow
    workflowFeature.delegate = groupsFeature
    commandsFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap { $0.workflows }.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap {
      $0.workflows.flatMap { $0.commands }
    }.count, 3)

    commandsFeature.perform(.moveCommand(command, offset: -2, in: workflow))

    wait(for: [expectation], timeout: 10.0)
  }

  func testDeleteCommand() {
    let expectation = self.expectation(description: "Wait for callback")
    let identifier = UUID().uuidString
    let removedCommand: Command = .script(.appleScript(.path("path"), "appleScript"))
    let commands: [Command] = [
      removedCommand,
      .script(.shell(.path("path"), "shellScript")),
      .open(.init(id: identifier, path: "path/to/file"))
    ]
    let expected: [Command] = [
      .script(.shell(.path("path"), "shellScript")),
      .open(.init(id: identifier, path: "path/to/file"))
    ]
    var group = Group.empty()
    var workflow = Workflow.empty()
    workflow.commands = commands
    group.workflows = [workflow]

    let groupsController = GroupsController(groups: [group])
    let commandController = CommandControllerMock()
    let coreController = CoreControllerMock(commandController: commandController,
                                            groupsController: groupsController) { state in
      switch state {
      case .respondTo,
           .reloadContext,
           .activate:
        XCTFail("Wrong state, should end up in `.didReloadGroups`")
      case .didReloadGroups(let groups):
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groupsController.groups.count, 1)
        XCTAssertEqual(groups, groupsController.groups)

        guard let group = groups.first else {
          XCTFail("Failed to find first group.")
          return
        }

        XCTAssertEqual(group.workflows.count, 1)

        guard let workflow = group.workflows.first else {
          XCTFail("Failed to find first workflow.")
          return
        }

        XCTAssertEqual(workflow.commands.count, 2)
        XCTAssertEqual(expected, workflow.commands)

        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController)
    let groupsFeature = factory.groupFeature(userSelection: userSelection)
    let workflowFeature = factory.workflowFeature()
    let commandsFeature = factory.commandsFeature(commandController: coreController.commandController)

    userSelection.group = group
    userSelection.workflow = workflow
    workflowFeature.delegate = groupsFeature
    commandsFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap { $0.workflows }.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap {
      $0.workflows.flatMap { $0.commands }
    }.count, 3)

    commandsFeature.perform(.deleteCommand(removedCommand, in: workflow))

    wait(for: [expectation], timeout: 10.0)
  }
}

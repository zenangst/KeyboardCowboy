@testable import Keyboard_Cowboy
@testable import LogicFramework
@testable import ViewKit
import Foundation
import XCTest

// swiftlint:disable function_body_length type_body_length
class CommandsFeatureControllerTests: XCTestCase {
  func testCreateCommand() {
    let expectation = self.expectation(description: "Wait for callback")
    var group = Group.empty()
    let workflow = Workflow.empty()
    group.workflows = [workflow]

    let commandMapper = ViewModelMapperFactory().commandMapper()
    let logicApplicationCommand = ApplicationCommand(application: Application.finder())
    let command = Command.application(logicApplicationCommand)
    let viewModel = commandMapper.map(command)

    let groupsController = GroupsController(groups: [group])
    let coreController = CoreControllerMock(groupsController: groupsController) { state in
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
        case .application(let applicationCommand):
          XCTAssertEqual(applicationCommand.application, logicApplicationCommand.application)
        case .keyboard, .open, .script:
          XCTFail("Wrong command kind. Should be `.application`")
        }

        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: userSelection)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()
    let commandsFeature = factory.commandsFeature()
    let groupMapper = ViewModelMapperFactory().groupMapper()
    let workflowMapper = ViewModelMapperFactory().workflowMapper()

    userSelection.group = groupMapper.map(group)
    userSelection.workflow = workflowMapper.map(workflow)
    workflowFeature.delegate = groupsFeature
    commandsFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap({ $0.workflows }).count, 1)

    commandsFeature.perform(.createCommand(viewModel))

    wait(for: [expectation], timeout: 10.0)
  }

  func testUpdateCommand() {
    let expectation = self.expectation(description: "Wait for callback")

    let commandMapper = ViewModelMapperFactory().commandMapper()
    let logicApplicationCommand = ApplicationCommand(application: Application.finder())
    let command = Command.application(logicApplicationCommand)
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
    let coreController = CoreControllerMock(groupsController: groupsController) { state in
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
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: userSelection)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()
    let commandsFeature = factory.commandsFeature()
    let groupMapper = ViewModelMapperFactory().groupMapper()
    let workflowMapper = ViewModelMapperFactory().workflowMapper()

    userSelection.group = groupMapper.map(group)
    userSelection.workflow = workflowMapper.map(workflow)
    workflowFeature.delegate = groupsFeature
    commandsFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap({ $0.workflows }).count, 1)

    let updatedViewModel = commandMapper.map(updatedCommand)
    commandsFeature.perform(.updateCommand(updatedViewModel))

    wait(for: [expectation], timeout: 10.0)
  }

  func testMoveCommand() {
    let expectation = self.expectation(description: "Wait for callback")
    let identifier = UUID().uuidString
    let commands: [Command] = [
      .script(.appleScript(.path("path"), "appleScript")),
      .script(.shell(.path("path"), "shellScript")),
      .open(.init(id: identifier, path: "path/to/file"))
    ]
    let expected: [Command] = [
      .open(.init(id: identifier, path: "path/to/file")),
      .script(.appleScript(.path("path"), "appleScript")),
      .script(.shell(.path("path"), "shellScript"))
    ]
    var group = Group.empty()
    var workflow = Workflow.empty()
    workflow.commands = commands
    group.workflows = [workflow]

    let groupsController = GroupsController(groups: [group])
    let coreController = CoreControllerMock(groupsController: groupsController) { state in
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
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: userSelection)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()
    let commandsFeature = factory.commandsFeature()
    let groupMapper = ViewModelMapperFactory().groupMapper()
    let workflowMapper = ViewModelMapperFactory().workflowMapper()

    userSelection.group = groupMapper.map(group)
    userSelection.workflow = workflowMapper.map(workflow)
    workflowFeature.delegate = groupsFeature
    commandsFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap { $0.workflows }.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap {
      $0.workflows.flatMap { $0.commands }
    }.count, 3)

    commandsFeature.perform(.moveCommand(from: 2, to: 0))

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
    let coreController = CoreControllerMock(groupsController: groupsController) { state in
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
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: userSelection)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()
    let commandsFeature = factory.commandsFeature()
    let groupMapper = ViewModelMapperFactory().groupMapper()
    let workflowMapper = ViewModelMapperFactory().workflowMapper()

    userSelection.group = groupMapper.map(group)
    userSelection.workflow = workflowMapper.map(workflow)
    workflowFeature.delegate = groupsFeature
    commandsFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap { $0.workflows }.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap {
      $0.workflows.flatMap { $0.commands }
    }.count, 3)

    let commandMapper = ViewModelMapperFactory().commandMapper()
    let removedViewModel = commandMapper.map(removedCommand)
    commandsFeature.perform(.deleteCommand(removedViewModel))

    wait(for: [expectation], timeout: 10.0)
  }
}

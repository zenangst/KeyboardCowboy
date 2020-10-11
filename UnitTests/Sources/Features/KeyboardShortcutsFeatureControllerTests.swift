@testable import Keyboard_Cowboy
@testable import LogicFramework
@testable import ViewKit
import Foundation
import XCTest

// swiftlint:disable function_body_length type_body_length
class KeyboardShortcutsFeatureControllerTests: XCTestCase {
  func testCreateKeyboardShortcut() {
    let expectation = self.expectation(description: "Wait for callback")
    var group = Group.empty()
    let workflow = Workflow.empty()
    group.workflows = [workflow]

    let keyboardShortcutMapper = ViewModelMapperFactory().keyboardShortcutMapper()
    let keyboardShortcut = KeyboardShortcut(id: UUID().uuidString, key: "A", modifiers: [.command, .shift])
    let viewModel = keyboardShortcutMapper.map(keyboardShortcut)

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

        XCTAssertEqual(workflow.keyboardShortcuts.count, 1)
        XCTAssertEqual(workflow.commands.count, 0)

        guard let newKeyboardShortcut = workflow.keyboardShortcuts.first else {
          XCTFail("Failed to find first workflow.")
          return
        }

        XCTAssertEqual(keyboardShortcut, newKeyboardShortcut)

        expectation.fulfill()
      }
    }

    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: userSelection)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()
    let keyboardFeature = factory.keyboardShortcutsFeature()
    let groupMapper = ViewModelMapperFactory().groupMapper()
    let workflowMapper = ViewModelMapperFactory().workflowMapper()

    userSelection.group = groupMapper.map(group)
    userSelection.workflow = workflowMapper.map(workflow)
    workflowFeature.delegate = groupsFeature
    keyboardFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap({ $0.workflows }).count, 1)

    keyboardFeature.perform(.createKeyboardShortcut(viewModel))

    wait(for: [expectation], timeout: 10.0)
  }

  func testUpdateKeyboardShortcut() {
    let expectation = self.expectation(description: "Wait for callback")
    var group = Group.empty()
    var workflow = Workflow.empty()
    let identifier = UUID().uuidString
    let keyboardShortcut = KeyboardShortcut(id: identifier, key: "A", modifiers: [.command, .shift])
    workflow.keyboardShortcuts = [keyboardShortcut]
    group.workflows = [workflow]

    let keyboardShortcutMapper = ViewModelMapperFactory().keyboardShortcutMapper()
    let updatedKeyboardShortcut = KeyboardShortcut(id: identifier, key: "B", modifiers: [.command, .shift])
    let updatedViewModel = keyboardShortcutMapper.map(updatedKeyboardShortcut)

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

        XCTAssertEqual(workflow.keyboardShortcuts.count, 1)
        XCTAssertEqual(workflow.commands.count, 0)

        XCTAssertFalse(workflow.keyboardShortcuts.contains(keyboardShortcut))

        guard let newKeyboardShortcut = workflow.keyboardShortcuts.first else {
          XCTFail("Failed to find first workflow.")
          return
        }

        XCTAssertEqual(updatedKeyboardShortcut, newKeyboardShortcut)
      }
      expectation.fulfill()
    }

    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: userSelection)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()
    let keyboardFeature = factory.keyboardShortcutsFeature()
    let groupMapper = ViewModelMapperFactory().groupMapper()
    let workflowMapper = ViewModelMapperFactory().workflowMapper()

    userSelection.group = groupMapper.map(group)
    userSelection.workflow = workflowMapper.map(workflow)
    workflowFeature.delegate = groupsFeature
    keyboardFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap({ $0.workflows }).count, 1)
    XCTAssertEqual(groupsController.groups
                    .flatMap({ $0.workflows })
                    .flatMap({ $0.keyboardShortcuts }).count, 1)

    keyboardFeature.perform(.updateKeyboardShortcut(updatedViewModel))

    wait(for: [expectation], timeout: 10.0)
  }

  func testMoveKeyboardShortcut() {
    let expectation = self.expectation(description: "Wait for callback")
    let movedKeyboardShortcut: KeyboardShortcut = KeyboardShortcut(id: UUID().uuidString,
                                                                   key: "A", modifiers: [.shift])
    let keyboardShortcuts: [KeyboardShortcut] = [
      movedKeyboardShortcut,
      KeyboardShortcut(id: "B", key: "B", modifiers: [.shift]),
      KeyboardShortcut(id: "C", key: "C", modifiers: [.shift])
    ]
    let expected: [KeyboardShortcut] = [
      KeyboardShortcut(id: "B", key: "B", modifiers: [.shift]),
      KeyboardShortcut(id: "C", key: "C", modifiers: [.shift]),
      movedKeyboardShortcut
    ]
    var group = Group.empty()
    var workflow = Workflow.empty()
    workflow.keyboardShortcuts = keyboardShortcuts
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

        XCTAssertEqual(workflow.keyboardShortcuts.count, 3)
        XCTAssertEqual(expected, workflow.keyboardShortcuts)

        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: userSelection)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()
    let groupMapper = ViewModelMapperFactory().groupMapper()
    let workflowMapper = ViewModelMapperFactory().workflowMapper()
    let keyboardFeature = factory.keyboardShortcutsFeature()

    userSelection.group = groupMapper.map(group)
    userSelection.workflow = workflowMapper.map(workflow)
    workflowFeature.delegate = groupsFeature
    keyboardFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap { $0.workflows }.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap {
      $0.workflows.flatMap { $0.keyboardShortcuts }
    }.count, 3)

    keyboardFeature.perform(.moveCommand(from: 0, to: 2))

    wait(for: [expectation], timeout: 10.0)
  }

  func testDeleteKeyboardShortcut() {
    let expectation = self.expectation(description: "Wait for callback")
    let removedKeyboardShortcut: KeyboardShortcut = KeyboardShortcut(id: UUID().uuidString,
                                                                     key: "A", modifiers: [.shift])
    let keyboardShortcuts: [KeyboardShortcut] = [
      removedKeyboardShortcut,
      KeyboardShortcut(id: "B", key: "B", modifiers: [.shift]),
      KeyboardShortcut(id: "C", key: "C", modifiers: [.shift])
    ]
    let expected: [KeyboardShortcut] = [
      KeyboardShortcut(id: "B", key: "B", modifiers: [.shift]),
      KeyboardShortcut(id: "C", key: "C", modifiers: [.shift])
    ]
    var group = Group.empty()
    var workflow = Workflow.empty()
    workflow.keyboardShortcuts = keyboardShortcuts
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

        XCTAssertEqual(workflow.keyboardShortcuts.count, 2)
        XCTAssertEqual(expected, workflow.keyboardShortcuts)

        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: userSelection)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()
    let groupMapper = ViewModelMapperFactory().groupMapper()
    let workflowMapper = ViewModelMapperFactory().workflowMapper()
    let keyboardFeature = factory.keyboardShortcutsFeature()

    userSelection.group = groupMapper.map(group)
    userSelection.workflow = workflowMapper.map(workflow)
    workflowFeature.delegate = groupsFeature
    keyboardFeature.delegate = workflowFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap { $0.workflows }.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap {
      $0.workflows.flatMap { $0.keyboardShortcuts }
    }.count, 3)

    let keyboardShortcutMapper = ViewModelMapperFactory().keyboardShortcutMapper()
    let removedViewModel = keyboardShortcutMapper.map(removedKeyboardShortcut)
    keyboardFeature.perform(.deleteKeyboardShortcut(removedViewModel))

    wait(for: [expectation], timeout: 10.0)
  }
}

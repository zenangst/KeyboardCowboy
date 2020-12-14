@testable import Keyboard_Cowboy
@testable import LogicFramework
@testable import ModelKit
import Foundation
import ViewKit
import XCTest

class WorkflowFeatureControllerTests: XCTestCase {
  func testCreateWorkflow() {
    let expectation = self.expectation(description: "Wait for callback")
    let group = Group.empty()
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

        XCTAssertEqual(group.workflows.count, 2)

        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let factory = FeatureFactory(coreController: coreController)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()

    workflowFeature.delegate = groupsFeature

    XCTAssertEqual(groupsController.groups.count, 1)

    workflowFeature.perform(.create(groupId: group.id))

    wait(for: [expectation], timeout: 10.0)
  }

  func testUpdateWorkflow() {
    let expectation = self.expectation(description: "Wait for callback")
    let workflow = Workflow.empty()
    var updatedWorkflow = workflow
    updatedWorkflow.name = "Updated workflow"
    var group = Group.empty()
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

        XCTAssertFalse(group.workflows.contains(workflow))
        XCTAssertTrue(group.workflows.contains(updatedWorkflow))

        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let factory = FeatureFactory(coreController: coreController)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()

    workflowFeature.delegate = groupsFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap({ $0.workflows }).count, 1)

    workflowFeature.perform(.update(updatedWorkflow))

    wait(for: [expectation], timeout: 10.0)
  }

  func testDeleteWorkflow() {
    let expectation = self.expectation(description: "Wait for callback")
    let workflow = Workflow.empty()
    var group = Group.empty()
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

        XCTAssertEqual(group.workflows.count, 0)
        XCTAssertFalse(group.workflows.contains(workflow))

        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let factory = FeatureFactory(coreController: coreController)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()

    workflowFeature.delegate = groupsFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap({ $0.workflows }).count, 1)

    workflowFeature.perform(.delete(workflow))

    wait(for: [expectation], timeout: 10.0)
  }
}

@testable import Keyboard_Cowboy
@testable import LogicFramework
import Foundation
import ViewKit
import XCTest

class WorkflowFeatureControllerTests: XCTestCase {
  func testCreateWorkflow() {
    let expectation = self.expectation(description: "Wait for callback")
    let group = Group.empty()
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

        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: userSelection)
    let groupsFeature = factory.groupFeature()
    let workflowFeature = factory.workflowFeature()
    let mapper = ViewModelMapperFactory().groupMapper()

    userSelection.group = mapper.map(group)
    workflowFeature.delegate = groupsFeature

    XCTAssertEqual(groupsController.groups.count, 1)

    workflowFeature.perform(.createWorkflow)

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

        XCTAssertFalse(group.workflows.contains(workflow))
        XCTAssertTrue(group.workflows.contains(updatedWorkflow))

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

    userSelection.group = groupMapper.map(group)
    workflowFeature.delegate = groupsFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap({ $0.workflows }).count, 1)

    let newViewModel = workflowMapper.map(updatedWorkflow)
    workflowFeature.perform(.updateWorkflow(newViewModel))

    wait(for: [expectation], timeout: 10.0)
  }

  func testDeleteWorkflow() {
    let expectation = self.expectation(description: "Wait for callback")
    let workflow = Workflow.empty()
    var group = Group.empty()
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

        XCTAssertEqual(group.workflows.count, 0)
        XCTAssertFalse(group.workflows.contains(workflow))

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

    userSelection.group = groupMapper.map(group)
    workflowFeature.delegate = groupsFeature

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertEqual(groupsController.groups.flatMap({ $0.workflows }).count, 1)

    let viewModel = workflowMapper.map(workflow)
    workflowFeature.perform(.deleteWorkflow(viewModel))

    wait(for: [expectation], timeout: 10.0)
  }
}

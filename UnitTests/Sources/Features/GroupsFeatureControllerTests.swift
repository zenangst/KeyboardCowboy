@testable import Keyboard_Cowboy
@testable import LogicFramework
@testable import ModelKit
import Foundation
import ViewKit
import XCTest

class GroupsFeatureControllerTests: XCTestCase {
  func testCreateGroup() {
    let expectation = self.expectation(description: "Wait for callback")
    let groupsController = GroupsController(groups: [])
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
        expectation.fulfill()
      }
    }
    groupsController.delegate = coreController

    let factory = FeatureFactory(coreController: coreController)
    let groupsFeature = factory.groupFeature(userSelection: UserSelection())

    XCTAssertEqual(groupsController.groups.count, 0)

    groupsFeature.perform(.createGroup)

    wait(for: [expectation], timeout: 1.0)
  }

  func testDeleteGroup() {
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
        XCTAssertEqual(groups.count, 0)
        XCTAssertEqual(groupsController.groups.count, 0)
        XCTAssertEqual(groups, groupsController.groups)
        expectation.fulfill()
      }
    }

    groupsController.delegate = coreController

    let factory = FeatureFactory(coreController: coreController)
    let groupsFeature = factory.groupFeature(userSelection: UserSelection())

    XCTAssertEqual(groupsController.groups.count, 1)

    groupsFeature.perform(.deleteGroup(group))

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdateGroup() {
    let expectation = self.expectation(description: "Wait for callback")
    let oldGroup = Group.empty()
    var newGroup = oldGroup
    newGroup.name = "Updated group"

    let groupsController = GroupsController(groups: [oldGroup])
    let commandController = CommandControllerMock()
    let coreController = CoreControllerMock(commandController: commandController,
                                            groupsController: groupsController) { state in
      switch state {
      case .respondTo,
           .reloadContext,
           .activate:
        XCTFail("Wrong state, should end up in `.didReloadGroups`")
      case .didReloadGroups(let groups):
        XCTAssertFalse(groups.contains(oldGroup))
        XCTAssertTrue(groups.contains(newGroup))
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groupsController.groups.count, 1)
        XCTAssertEqual(groups, groupsController.groups)
        expectation.fulfill()
      }
    }

    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController)
    let groupsFeature = factory.groupFeature(userSelection: userSelection)

    XCTAssertEqual(groupsController.groups.count, 1)
    XCTAssertTrue(groupsController.groups.contains(oldGroup))

    groupsFeature.perform(.updateGroup(newGroup))

    wait(for: [expectation], timeout: 1.0)
  }

  func testDropFile() {
    let expectation = self.expectation(description: "Wait for callback")
    let application = Application.finder()
    let groupsController = GroupsController(groups: [])
    let commandController = CommandControllerMock()
    let coreController = CoreControllerMock(commandController: commandController,
                                            groupsController: groupsController) { state in
      switch state {
      case .respondTo,
           .reloadContext,
           .activate:
        XCTFail("Wrong state, should end up in `.didReloadGroups`")
      case .didReloadGroups(let groups):
        defer { expectation.fulfill() }

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groupsController.groups.count, 1)
        XCTAssertEqual(groups, groupsController.groups)

        guard let group = groups.first else {
          XCTFail("Unable to find group")
          return
        }

        XCTAssertEqual(group.name, application.bundleName)
        XCTAssertEqual(group.rule?.bundleIdentifiers.count, 1)
        XCTAssertTrue(group.rule?.bundleIdentifiers.contains(application.bundleIdentifier) == true)
      }
    }
    coreController.installedApplications = [application]

    groupsController.delegate = coreController

    let userSelection = UserSelection()
    let factory = FeatureFactory(coreController: coreController)
    let groupsFeature = factory.groupFeature(userSelection: userSelection)

    groupsFeature.perform(.dropFile([URL(fileURLWithPath: application.path)]))

    wait(for: [expectation], timeout: 1.0)
  }
}

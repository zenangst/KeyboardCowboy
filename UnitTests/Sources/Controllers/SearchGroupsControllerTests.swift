@testable import Keyboard_Cowboy
import ModelKit
import ViewKit
import XCTest

class SearchGroupsControllerTests: XCTestCase {

  func testSearchForGroupWithPerfectNameMatch() {
    let groupsController = GroupsControllerMock { _ in }
    let coreController = CoreControllerMock(groupsController: groupsController) { _ in }
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: UserSelection())
    let search = factory.searchFeature(userSelection: UserSelection())

    let query = "My awesome group"
    let groups = [
      Group(name: query)
    ]
    groupsController.groups = groups

    XCTAssertEqual(search.state, SearchResults.empty())
    search.perform(.search(query))

    XCTAssertEqual(search.state.groups, groups)
    XCTAssertEqual(search.state.workflows, [])
    XCTAssertEqual(search.state.commands, [])
  }

  func testSearchForGroupWithPartialMatch() {
    let groupsController = GroupsControllerMock { _ in }
    let coreController = CoreControllerMock(groupsController: groupsController) { _ in }
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: UserSelection())
    let search = factory.searchFeature(userSelection: UserSelection())

    let query = "Group"
    let groups = [
      Group(name: "Group A"),
      Group(name: "Group B"),
      Group(name: "Group C")
    ]

    groupsController.groups = groups

    XCTAssertEqual(search.state.groups, [])
    XCTAssertEqual(search.state.workflows, [])
    XCTAssertEqual(search.state.commands, [])
    search.perform(.search(query))
    XCTAssertEqual(search.state.groups, groups)
    XCTAssertEqual(search.state.workflows, [])
    XCTAssertEqual(search.state.commands, [])
  }

  func testSearchForGroupWithPartialMatchCaseInsensitive() {
    let groupsController = GroupsControllerMock { _ in }
    let coreController = CoreControllerMock(groupsController: groupsController) { _ in }
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: UserSelection())
    let search = factory.searchFeature(userSelection: UserSelection())

    let query = "Group"
    let groups = [
      Group(name: "group a"),
      Group(name: "group b"),
      Group(name: "group c")
    ]

    groupsController.groups = groups

    XCTAssertEqual(search.state.groups, [])
    search.perform(.search(query))
    XCTAssertEqual(search.state.groups, groups)
    XCTAssertEqual(search.state.workflows, [])
    XCTAssertEqual(search.state.commands, [])
  }

  func testSearchForWorkflowByName() {
    let groupsController = GroupsControllerMock { _ in }
    let coreController = CoreControllerMock(groupsController: groupsController) { _ in }
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: UserSelection())
    let search = factory.searchFeature(userSelection: UserSelection())

    let query = "Workflow A"
    let workflow = Workflow(name: "Workflow A")
    let groupA = Group(name: "Group A",
                       workflows: [workflow])
    let groups = [
      groupA,
      Group(name: "Group B",
            workflows: [Workflow(name: "Workflow B")]),
      Group(name: "Group C",
            workflows: [Workflow(name: "Workflow C")])
    ]
    let expected = [groupA]

    groupsController.groups = groups

    XCTAssertEqual(search.state.groups, [])
    XCTAssertEqual(search.state.workflows, [])
    XCTAssertEqual(search.state.commands, [])
    search.perform(.search(query))
    XCTAssertEqual(search.state.groups, expected)
    XCTAssertEqual(search.state.workflows, [workflow])
    XCTAssertEqual(search.state.commands, [])
  }

  func testSearchForCommandByName() {
    let groupsController = GroupsControllerMock { _ in }
    let coreController = CoreControllerMock(groupsController: groupsController) { _ in }
    let factory = FeatureFactory(coreController: coreController,
                                 userSelection: UserSelection())
    let search = factory.searchFeature(userSelection: UserSelection())

    let query = "Command A"
    let commandA = Command.open(.init(name: "Command A", path: "/path/to/file"))
    let workflowA = Workflow(name: "Workflow A", commands: [commandA])
    let groupA = Group(name: "Group A",
                       workflows: [workflowA])
    let groups = [
      groupA,
      Group(name: "Group B",
            workflows: [
              Workflow(name: "Workflow B",
                       commands: [Command.open(.init(name: "Command B", path: "/path/to/file"))]
              )
            ]),
      Group(name: "Group C",
            workflows: [
              Workflow(name: "Workflow C",
                       commands: [Command.open(.init(name: "Command C", path: "/path/to/file"))])
            ])
    ]
    let expected = [groupA]

    groupsController.groups = groups

    XCTAssertEqual(search.state.groups, [])
    XCTAssertEqual(search.state.workflows, [])
    XCTAssertEqual(search.state.commands, [])
    search.perform(.search(query))
    XCTAssertEqual(search.state.groups, expected)
    XCTAssertEqual(search.state.workflows, [workflowA])
    XCTAssertEqual(search.state.commands, [commandA])
  }
}

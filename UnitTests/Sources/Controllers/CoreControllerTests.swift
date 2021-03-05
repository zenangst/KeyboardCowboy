@testable import LogicFramework
import ModelKit
import XCTest

class CoreControllerTests: XCTestCase {
  func testCoreController() {
    let factory = ControllerFactory.shared
    let id = UUID().uuidString
    let groups = self.groups(id: id)
    let openCommandController = OpenCommandControllerMock(.success(()))
    let commandController = factory.commandController(
      openCommandController: openCommandController)
    let groupsController = factory.groupsController(groups: groups)
    let runningApplication = RunningApplicationMock(activate: true, bundleIdentifier: "com.apple.finder")
    let workspace = WorkspaceProviderMock(
      applications: [runningApplication], launchApplicationResult: true,
      openFileResult: WorkspaceProviderMock.OpenResult(nil, nil))

    workspace.frontApplication = runningApplication

    let builtInController = BuiltInCommandControllerMock()
    let workflowController = factory.workflowController()
    let controller = factory.coreController(
      .disabled,
      bundleIdentifier: "com.zenangst.KeyboardCowboy.UnitTests",
      commandController: commandController,
      builtInCommandController: builtInController,
      groupsController: groupsController,
      installedApplications: [],
      workflowController: workflowController,
      workspace: workspace)

    let firstBatch = controller.respond(to: .init(id: id, key: "G", modifiers: [.control, .option]))
    XCTAssertEqual(firstBatch.count, 2)
    XCTAssertEqual(groups[0].workflows[1], firstBatch[0])
    XCTAssertEqual(groups[0].workflows[2], firstBatch[1])

    let secondBatch = controller.respond(to: .init(id: id, key: "H"))
    XCTAssertEqual(secondBatch.count, 1)
    XCTAssertEqual(groups[0].workflows[1], secondBatch[0])
  }

  func testInterceptPerformance() {
    let factory = ControllerFactory.shared
    let id = UUID().uuidString
    let groups = self.groups(id: id)
    let expectation = self.expectation(description: "Wait for command controller to run commands")
    let commandController = CommandControllerMock { _ in
      expectation.fulfill()
    }
    let groupsController = factory.groupsController(groups: groups)
    let runningApplication = RunningApplicationMock(activate: true, bundleIdentifier: "com.apple.finder")
    let workspace = WorkspaceProviderMock(
      applications: [runningApplication], launchApplicationResult: true,
      openFileResult: WorkspaceProviderMock.OpenResult(nil, nil))

    workspace.frontApplication = runningApplication

    let workflowController = WorkflowControllerMock()
    let builtInController = BuiltInCommandControllerMock()
    let controller = factory.coreController(
      .disabled,
      bundleIdentifier: "com.zenangst.KeyboardCowboy.UnitTests",
      commandController: commandController,
      builtInCommandController: builtInController,
      groupsController: groupsController,
      installedApplications: [],
      workflowController: workflowController,
      workspace: workspace)

    let event = CGEvent(keyboardEventSource: nil, virtualKey: 32, keyDown: true)!
    let context = HotKeyContext(event: event,
                                eventSource: nil,
                                type: .keyDown,
                                result: nil)

    let keyCodeMapper = KeyCodeMapper.shared
    var workflows = [Workflow]()

    for (key, _) in keyCodeMapper.stringLookup {
      let workflow = Workflow(name: key, keyboardShortcuts: [
        KeyboardShortcut(key: key)
      ], commands: [])
      workflows.append(workflow)
    }

    workflowController.workflows = workflows
    workflowController.filteredWorkflows = [
      Workflow(name: "Success")
    ]

    controller.activate(workflows: workflows)

    measure {
      controller.intercept(context)
    }

    wait(for: [expectation], timeout: 10)
  }

  private func groups(id: String = UUID().uuidString) -> [Group] {
    [
      Group(name: "Global shortcuts",
            workflows:
              [
                Workflow(
                  id: id,
                  name: "Open Finder",
                  keyboardShortcuts: [
                    KeyboardShortcut(id: id, key: "F", modifiers: [.control, .option])
                  ],
                  commands: [
                    .application(.init(application: .init(
                                        bundleIdentifier: "com.apple.finder",
                                        bundleName: "Finder",
                                        path: "/System/Library/CoreServices/Finder.app")))
                  ]),
                Workflow(
                  id: id,
                  name: "Open GitHub - Homepage",
                  keyboardShortcuts: [
                    KeyboardShortcut(id: id, key: "G", modifiers: [.control, .option]),
                    KeyboardShortcut(id: id, key: "H")
                  ],
                  commands: [
                    .open(.init(application: .init(bundleIdentifier: "com.apple.Safari",
                                                   bundleName: "Safari",
                                                   path: "/Applications/Safari.app"),
                                path: "https://www.github.com"))
                  ]),
                Workflow(
                  id: id,
                  name: "Open GitHub - Participating",
                  keyboardShortcuts: [
                    KeyboardShortcut(id: id, key: "G", modifiers: [.control, .option]),
                    KeyboardShortcut(id: id, key: "P")
                  ],
                  commands: [
                    .open(.init(
                            application: .init(bundleIdentifier: "com.apple.Safari",
                                               bundleName: "Safari",
                                               path: "/Applications/Safari.app"),
                            path: "https://github.com/notifications?query=reason%3Aparticipating"))
                  ])
              ])
    ]
  }
}

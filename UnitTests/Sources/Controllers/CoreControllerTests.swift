import LogicFramework
import ModelKit
import XCTest

class CoreControllerTests: XCTestCase {
  func testCoreController() {
    let factory = ControllerFactory()
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

    let workflowController = factory.workflowController()
    let controller = factory.coreController(
      commandController: commandController,
      disableKeyboardShortcuts: true,
      groupsController: groupsController,
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

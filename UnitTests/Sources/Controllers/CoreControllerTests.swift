import LogicFramework
import XCTest

class CoreControllerTests: XCTestCase {
  func testCoreController() {
    let factory = ControllerFactory()
    let groups = self.groups()
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
      groupsController: groupsController,
      workflowController: workflowController,
      workspace: workspace)

    let firstBatch = controller.respond(to: .init(key: "G", modifiers: [.control, .option]))
    XCTAssertEqual(firstBatch.count, 2)
    XCTAssertEqual(groups[0].workflows[1], firstBatch[0])
    XCTAssertEqual(groups[0].workflows[2], firstBatch[1])

    let secondBatch = controller.respond(to: .init(key: "H"))
    XCTAssertEqual(secondBatch.count, 1)
    XCTAssertEqual(groups[0].workflows[1], secondBatch[0])
  }

  private func groups() -> [Group] {
    [
      Group(name: "Global shortcuts",
            workflows:
              [
                Workflow(commands: [
                  .application(.init(application: .init(
                                      bundleIdentifier: "com.apple.finder",
                                      bundleName: "Finder",
                                      path: "/System/Library/CoreServices/Finder.app")))
                ],
                keyboardShortcuts: [
                  KeyboardShortcut(key: "F", modifiers: [.control, .option])
                ],
                name: "Open Finder"),
                Workflow(commands: [
                  .open(.init(application: .init(bundleIdentifier: "com.apple.Safari",
                                                 bundleName: "Safari",
                                                 path: "/Applications/Safari.app"),
                              path: "https://www.github.com"))
                ],
                keyboardShortcuts: [
                  KeyboardShortcut(key: "G", modifiers: [.control, .option]),
                  KeyboardShortcut(key: "H")
                ],
                name: "Open GitHub - Homepage"),
                Workflow(commands: [
                  .open(.init(
                          application: .init(bundleIdentifier: "com.apple.Safari",
                                             bundleName: "Safari",
                                             path: "/Applications/Safari.app"),
                          path: "https://github.com/notifications?query=reason%3Aparticipating"))
                ],
                keyboardShortcuts: [
                  KeyboardShortcut(key: "G", modifiers: [.control, .option]),
                  KeyboardShortcut(key: "P")
                ],
                name: "Open GitHub - Participating")
              ])
    ]
  }
}

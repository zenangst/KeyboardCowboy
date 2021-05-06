import XCTest
@testable import ModelKit
@testable import LogicFramework

class ApplicationTriggerControllerTests: XCTestCase {
  static let finderCommand = Command.builtIn(.init(kind: .quickRun))
  static let calendarLaunchedCommand = Command.builtIn(.init(kind: .quickRun))
  static let calendarClosedCommand = Command.builtIn(.init(kind: .quickRun))
  static let workflows = [
    Workflow(name: "Finder workflow",
             trigger: .application(
              [ApplicationTrigger(application: Application.finder(),
                                  contexts: [.frontMost])]
             ),
             commands: [finderCommand]
    ),
    Workflow(name: "Calendar workflow - Launched",
             trigger: .application(
              [ApplicationTrigger(application: Application.calendar(),
                                  contexts: [.launched])]
             ),
             commands: [calendarLaunchedCommand]
    ),
    Workflow(name: "Calendar workflow - Closed",
             trigger: .application(
              [ApplicationTrigger(application: Application.calendar(),
                                  contexts: [.closed])]
             ),
             commands: [calendarClosedCommand]
    ),
    Workflow(name: "Messages workflow",
             trigger: .application(
              [ApplicationTrigger(application: Application.messages(),
                                  contexts: [.frontMost])]
             )
    )
  ]
  let groups = [Group(name: "Group", workflows: workflows)]

  func testApplicationTriggers() {
    let ctx = context { _ in }

    ctx.controller.recieve(groups)

    // Verify that indexing of application triggers work correctly.

    XCTAssertEqual(ctx.controller.openActions.count, 1)
    XCTAssertEqual(ctx.controller.closeActions.count, 1)
    XCTAssertEqual(ctx.controller.activateActions.count, 2)

    XCTAssertEqual(ctx.controller.activateActions[Application.finder().bundleIdentifier], [Self.workflows[0]])
    XCTAssertEqual(ctx.controller.openActions[Application.calendar().bundleIdentifier], [Self.workflows[1]])
    XCTAssertEqual(ctx.controller.closeActions[Application.calendar().bundleIdentifier], [Self.workflows[2]])
    XCTAssertEqual(ctx.controller.activateActions[Application.messages().bundleIdentifier], [Self.workflows[3]])

    // Check that the Finder command is invoked
    do {
      let expectation = self.expectation(description: "Except the command to be invoked")
      ctx.command.handler = { commands in
        XCTAssertEqual(commands, [Self.finderCommand])
        expectation.fulfill()
      }

      ctx.controller.process(RunningApplicationMock(
                              activate: true,
                              bundleIdentifier: Application.finder().bundleIdentifier))

      wait(for: [expectation], timeout: 1)
    }

    // Nothing should be invoked when Calendar becomes the front most application
    // Calendar's command should only run when Calendar is launched.
    do {
      ctx.command.handler = { _ in
        XCTFail("Calendar is scoped to run when launched and not when it is the front most applicaiton")
      }
      ctx.controller.process(RunningApplicationMock(
                              activate: true,
                              bundleIdentifier: Application.calendar().bundleIdentifier))
    }

    // Nothing should be invoked when Music becomes the front most application
    do {
      ctx.command.handler = { _ in
        XCTFail("Music should be ignored when it is used as the front most application")
      }
      ctx.controller.process(RunningApplicationMock(
                              activate: true,
                              bundleIdentifier: Application.music().bundleIdentifier))
    }

    // Check that calendar gets tagged as launched.
    do {

      let bundleIdentifiers = [
        Application.finder().bundleIdentifier,
        Application.calendar().bundleIdentifier,
        Application.music().bundleIdentifier,
        Application.messages().bundleIdentifier,
      ]

      ctx.command.handler = { commands in
        XCTAssertEqual(commands, [Self.calendarLaunchedCommand])
      }
      ctx.controller.process(bundleIdentifiers)

      // Calendar launch commands should not be executed twice unless
      // calendar is closed and untagged.
      ctx.command.handler = { _ in
        XCTFail("Do not invoke launch commands twice")
      }
      ctx.controller.process(bundleIdentifiers)
    }

    // Check that Calendar gets untagged when it is closed and only runs once.
    do {
      let bundleIdentifiers = [
        Application.finder().bundleIdentifier,
        Application.music().bundleIdentifier,
        Application.messages().bundleIdentifier,
      ]

      ctx.command.handler = { commands in
        XCTAssertEqual(commands, [Self.calendarClosedCommand])
      }
      ctx.controller.process(bundleIdentifiers)

      ctx.command.handler = { _ in
        XCTFail("Calendar is already closed and shouldn't be invoked again")
      }
      ctx.controller.process(bundleIdentifiers)
    }
  }

  func testIndextingOfKeyboardShortcuts() {
    let ctx = context { _ in }
    let workflow = Workflow(name: "Workflow",
                            trigger: .keyboardShortcuts([]))
    let groups = [Group(name: "Group", workflows: [workflow])]

    ctx.controller.recieve(groups)

    XCTAssertEqual(ctx.controller.openActions.count, 0)
    XCTAssertEqual(ctx.controller.closeActions.count, 0)
    XCTAssertEqual(ctx.controller.activateActions.count, 0)
  }

  func testPerformance() {
    let ctx = context { _ in }
    let amount: Int = 100

    var groups = [Group]()
    for x in 0..<amount {
      var group = Group(name: "Group \(x)")
      for y in 0..<amount {
        let application: Application = y % 2 == 0 ? .music() : .messages()
        let context: ApplicationTrigger.Context = y % 2 != 0 ? .launched : .closed
        let trigger: ApplicationTrigger = ApplicationTrigger(
          application: .finder(),
          contexts: [context])
        var workflow = Workflow(name: "Workflow \(x)-\(y)", trigger: .application([trigger]))

        for z in 0..<amount {
          let command: Command = .application(
            ApplicationCommand(name: "Command \(x)-\(y)-\(z)",
                               application: application))
          workflow.commands = [command]
        }
        group.workflows = [workflow]
      }
      groups.append(group)
    }

    ctx.controller.recieve(groups)

    ctx.controller.process([Application.finder().bundleIdentifier])

    ctx.controller.process([])
  }

  private func context(_ handler: @escaping ([Command]) -> Void) -> (controller: ApplicationTriggerController,
                                                                     command: CommandControllerMock) {
    let commandController = CommandControllerMock(handler)
    let controller = ApplicationTriggerController(
      commandController: commandController,
      workspace: .shared,
      runningTests: true)
    return (controller, commandController)
  }
}

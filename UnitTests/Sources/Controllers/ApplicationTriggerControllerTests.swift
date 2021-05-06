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

    XCTAssertEqual(ctx.controller.storage.count, 3)

    XCTAssertNotNil(ctx.controller.storage[Application.finder().bundleIdentifier])
    XCTAssertNotNil(ctx.controller.storage[Application.calendar().bundleIdentifier])
    XCTAssertNotNil(ctx.controller.storage[Application.messages().bundleIdentifier])

    XCTAssertEqual(ctx.controller.storage[Application.finder().bundleIdentifier]?.count, 1)
    XCTAssertEqual(ctx.controller.storage[Application.calendar().bundleIdentifier]?.count, 2)
    XCTAssertEqual(ctx.controller.storage[Application.messages().bundleIdentifier]?.count, 1)

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
      XCTAssertNil(ctx.controller.tagged[.launched])
      XCTAssertNil(ctx.controller.tagged[.closed])

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
      XCTAssertEqual(ctx.controller.tagged[.launched]?.count, 1)

      // Calendar launch commands should not be executed twice unless
      // calendar is closed and untagged.
      ctx.command.handler = { _ in
        XCTFail("Do not invoke launch commands twice")
      }
      ctx.controller.process(bundleIdentifiers)
      XCTAssertEqual(ctx.controller.tagged[.launched]?.count, 1)
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
      XCTAssertEqual(ctx.controller.tagged[.launched]?.count, 0)

      ctx.command.handler = { _ in
        XCTFail("Calendar is already closed and shouldn't be invoked again")
      }
      ctx.controller.process(bundleIdentifiers)
      XCTAssertEqual(ctx.controller.tagged[.launched]?.count, 0)
    }
  }

  func testIndextingOfKeyboardShortcuts() {
    let ctx = context { _ in }
    let workflow = Workflow(name: "Workflow",
                            trigger: .keyboardShortcuts([]))
    let groups = [Group(name: "Group", workflows: [workflow])]

    ctx.controller.recieve(groups)

    XCTAssertNil(ctx.controller.storage[Application.finder().bundleIdentifier])
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

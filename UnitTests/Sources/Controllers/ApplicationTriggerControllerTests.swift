import Cocoa
import Combine
@testable import Keyboard_Cowboy
import MachPort
import XCTest

@MainActor
final class ApplicationTriggerControllerTests: XCTestCase {
  func testApplicationTriggerController_frontmost() {
    let ctx = context(.frontMost)
    let controller = ApplicationTriggerController(ctx.runner)

    // Run command when Finder becomes the frontmost application
    ctx.runner.concurrentRunHandler = { newCommand in
      XCTAssertEqual(ctx.command, newCommand.first)
    }

    controller.subscribe(to: ctx.groupPublisher.$groups)
    controller.subscribe(to: ctx.userSpace
      .$frontmostApplication)
    controller.subscribe(to: ctx.userSpace
      .$runningApplications)

    ctx.userSpace.injectFrontmostApplication(.init(ref: RunningApplicationMock.currentApp, bundleIdentifier: "com.apple.calendar", name: "Calendar", path: ""))

    ctx.userSpace.injectFrontmostApplication(.init(ref: RunningApplicationMock.currentApp, bundleIdentifier: "com.apple.finder", name: "Finder", path: ""))
  }

  func testApplicationTriggerController_launched() {
    let ctx = context(.launched)
    let controller = ApplicationTriggerController(ctx.runner)

    // Run command when Finder is launched.
    ctx.runner.concurrentRunHandler = { newCommand in
      XCTAssertEqual(ctx.command, newCommand.first)
    }

    controller.subscribe(to: ctx.groupPublisher.$groups)
    controller.subscribe(to: ctx.userSpace.$frontmostApplication)
    controller.subscribe(to: ctx.userSpace.$runningApplications)

    ctx.userSpace.injectRunningApplications([
      .init(ref: RunningApplicationMock.currentApp, bundleIdentifier: "com.apple.finder", name: "Finder", path: ""),
    ])
    ctx.userSpace.injectRunningApplications([
      .init(ref: RunningApplicationMock.currentApp, bundleIdentifier: "com.apple.calendar", name: "Calendar", path: ""),
    ])
  }

  func testApplicationTriggerController_closed() {
    let ctx = context(.closed)
    let controller = ApplicationTriggerController(ctx.runner)

    // Run command when Finder is closed.
    ctx.runner.concurrentRunHandler = { newCommand in
      XCTAssertEqual(ctx.command, newCommand.first)
    }

    controller.subscribe(to: ctx.groupPublisher.$groups)
    controller.subscribe(to: ctx.userSpace
      .$frontmostApplication)
    controller.subscribe(to: ctx.userSpace
      .$runningApplications)

    ctx.userSpace.injectRunningApplications([UserSpace.Application(ref: NSRunningApplication.current, bundleIdentifier: "com.apple.finder", name: "Finder", path: "")])
    ctx.userSpace.injectRunningApplications([])
  }

  @MainActor private func context(_ triggerContext: ApplicationTrigger.Context) -> (
    command: Command,
    groupPublisher: WorkGroupPublisher,
    runner: WorkflowRunner,
    userSpace: UserSpace,
  ) {
    let command = Command.text(.init(.insertText(.init("Type command.", mode: .instant, actions: []))))
    let runner = WorkflowRunner(
      concurrent: { _ in fatalError("Should not be invoked yet.") },
      serial: { _ in fatalError("Should not be invoked yet.") },
    )

    let group = WorkflowGroup(
      name: "Test Group",
      workflows: [
        Workflow(name: "Finder",
                 trigger: .application([.init(application: .finder(), contexts: [triggerContext])]),
                 execution: .concurrent,
                 commands: [command]),
      ],
    )

    let groupPublisher = WorkGroupPublisher(groups: [group])
    let userSpace = UserSpace.shared
    return (command,
            groupPublisher,
            runner,
            userSpace)
  }
}

private final class WorkGroupPublisher {
  @Published var groups: [WorkflowGroup]

  init(groups: [WorkflowGroup]) {
    self.groups = groups
  }
}

private final class WorkflowRunner: WorkflowRunning {
  var concurrentRunHandler: ([Command]) -> Void
  var serialRunHandler: ([Command]) -> Void

  init(concurrent: @escaping ([Command]) -> Void,
       serial: @escaping ([Command]) -> Void) {
    concurrentRunHandler = concurrent
    serialRunHandler = serial
  }

  func runCommands(in workflow: Keyboard_Cowboy.Workflow) {
    switch workflow.execution {
    case .concurrent:
      concurrentRunHandler(workflow.commands)
    case .serial:
      serialRunHandler(workflow.commands)
    }
  }

  func run(_ workflow: Keyboard_Cowboy.Workflow, executionOverride: Keyboard_Cowboy.Workflow.Execution?, machPortEvent _: MachPort.MachPortEvent, repeatingEvent _: Bool) {
    switch executionOverride ?? workflow.execution {
    case .concurrent:
      concurrentRunHandler(workflow.commands)
    case .serial:
      serialRunHandler(workflow.commands)
    }
  }
}

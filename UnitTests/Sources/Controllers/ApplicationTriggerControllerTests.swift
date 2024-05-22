@testable import Keyboard_Cowboy
import XCTest
import Combine
import Cocoa
import MachPort

final class ApplicationTriggerControllerTests: XCTestCase {
  func testApplicationTriggerController_frontMost() {
    let ctx = context(.frontMost)
    let controller = ApplicationTriggerController(ctx.runner)

    // Run command when Finder becomes the frontmost application
    ctx.runner.concurrentRunHandler = { newCommand in
      XCTAssertEqual(ctx.command, newCommand.first)
    }

    controller.subscribe(to: ctx.groupPublisher.$groups)
    controller.subscribe(to: ctx.userSpace
      .$frontMostApplication)
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
    controller.subscribe(to: ctx.userSpace.$frontMostApplication)
    controller.subscribe(to: ctx.userSpace.$runningApplications)

    ctx.userSpace.injectRunningApplications([
      .init(ref: RunningApplicationMock.currentApp, bundleIdentifier: "com.apple.finder", name: "Finder", path: "")
    ])
    ctx.userSpace.injectRunningApplications([
      .init(ref: RunningApplicationMock.currentApp, bundleIdentifier: "com.apple.calendar", name: "Calendar", path: "")
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
      .$frontMostApplication)
    controller.subscribe(to: ctx.userSpace
      .$runningApplications)


    ctx.userSpace.injectRunningApplications([UserSpace.Application(ref: NSRunningApplication.current, bundleIdentifier: "com.apple.finder", name: "Finder", path: "")])
    ctx.userSpace.injectRunningApplications([])
  }

  private func context(_ triggerContext: ApplicationTrigger.Context) -> (
    command: Command,
    groupPublisher: WorkGroupPublisher,
    runner: WorkflowRunner,
    userSpace: UserSpace) {
      let command = Command.text(.init(.insertText(.init("Type command.", mode: .instant))))
    let runner = WorkflowRunner(
      concurrent: { _ in fatalError("Should not be invoked yet.") },
      serial: { _ in fatalError("Should not be invoked yet.") })

    let group = WorkflowGroup(
      name: "Test Group",
      workflows: [
        Workflow(name: "Finder",
                 trigger: .application([.init(application: .finder(), contexts: [triggerContext])]),
                 execution: .concurrent,
                 commands: [command])
      ])

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
    self.concurrentRunHandler = concurrent
    self.serialRunHandler = serial
  }

  func runCommands(in workflow: Keyboard_Cowboy.Workflow) {
    switch workflow.execution {
    case .concurrent:
      concurrentRunHandler(workflow.commands)
    case .serial:
      serialRunHandler(workflow.commands)
    }
  }

  func run(_ workflow: Keyboard_Cowboy.Workflow, for shortcut: Keyboard_Cowboy.KeyShortcut, executionOverride: Keyboard_Cowboy.Workflow.Execution?, machPortEvent: MachPort.MachPortEvent, repeatingEvent: Bool) {
    switch executionOverride ?? workflow.execution {
    case .concurrent:
      concurrentRunHandler(workflow.commands)
    case .serial:
      serialRunHandler(workflow.commands)
    }
  }
}


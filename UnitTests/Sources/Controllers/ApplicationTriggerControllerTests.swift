@testable import Keyboard_Cowboy
import XCTest
import Combine
import Cocoa

final class ApplicationTriggerControllerTests: XCTestCase {
  func testApplicationTriggerController_frontMost() {
    let ctx = context(.frontMost)
    let controller = ApplicationTriggerController(ctx.runner)
    controller.subscribe(to: ctx.groupPublisher.$groups)
    controller.subscribe(to: ctx.workspacePublisher.$frontMostApplication)
    controller.subscribe(to: ctx.workspacePublisher.$runningApplications)

    ctx.workspacePublisher.frontMostApplication = RunningApplicationMock(bundleIdentifier: "com.apple.calendar")

    // Run command when Finder becomes the frontmost application
    ctx.runner.concurrentRunHandler = { newCommand in
      XCTAssertEqual(ctx.command, newCommand.first!)
    }
    ctx.workspacePublisher.frontMostApplication = RunningApplicationMock(bundleIdentifier: "com.apple.finder")
  }

  func testApplicationTriggerController_launched() {
    let ctx = context(.launched)
    let controller = ApplicationTriggerController(ctx.runner)
    controller.subscribe(to: ctx.groupPublisher.$groups)
    controller.subscribe(to: ctx.workspacePublisher.$frontMostApplication)
    controller.subscribe(to: ctx.workspacePublisher.$runningApplications)

    // Run command when Finder is launched.
    ctx.runner.concurrentRunHandler = { newCommand in
      XCTAssertEqual(ctx.command, newCommand.first!)
    }

    ctx.workspacePublisher.runningApplications = [RunningApplicationMock(bundleIdentifier: "com.apple.finder")]
    ctx.workspacePublisher.frontMostApplication = RunningApplicationMock(bundleIdentifier: "com.apple.calendar")
  }

  func testApplicationTriggerController_closed() {
    let ctx = context(.closed)
    let controller = ApplicationTriggerController(ctx.runner)
    controller.subscribe(to: ctx.groupPublisher.$groups)
    controller.subscribe(to: ctx.workspacePublisher.$frontMostApplication)
    controller.subscribe(to: ctx.workspacePublisher.$runningApplications)

    // Run command when Finder is closed.
    ctx.runner.concurrentRunHandler = { newCommand in
      XCTAssertEqual(ctx.command, newCommand.first!)
    }

    ctx.workspacePublisher.runningApplications = [RunningApplicationMock(bundleIdentifier: "com.apple.finder")]
    ctx.workspacePublisher.runningApplications = []
  }

  private func context(_ triggerContext: ApplicationTrigger.Context) -> (
    command: Command,
    groupPublisher: WorkGroupPublisher,
    runner: CommandRunner,
    workspacePublisher: WorkspacePublisherMock) {
    let command = Command.type(.init(name: "Type command",
                                     input: "Hello, Finder!"))
    let runner = CommandRunner(
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
    let workspacePublisher = WorkspacePublisherMock(runningApplications: [])
    return (command,
            groupPublisher,
            runner,
            workspacePublisher)
  }
}

private struct RunningApplicationMock: RunningApplication {
  var bundleIdentifier: String?
  func activate(options: NSApplication.ActivationOptions) -> Bool { false }
  func terminate() -> Bool { false }
}

private final class WorkspacePublisherMock: ObservableObject {
  @Published var runningApplications: [RunningApplication] = []
  @Published var frontMostApplication: (RunningApplication)?

  init(runningApplications: [RunningApplication],
       frontMostApplication: (RunningApplication)? = nil) {
    self.runningApplications = runningApplications
    self.frontMostApplication = frontMostApplication
  }
}

private final class WorkGroupPublisher {
  @Published var groups: [WorkflowGroup]

  init(groups: [WorkflowGroup]) {
    self.groups = groups
  }
}

private final class CommandRunner: CommandRunning {
  var concurrentRunHandler: ([Command]) -> Void
  var serialRunHandler: ([Command]) -> Void

  init(concurrent: @escaping ([Command]) -> Void,
       serial: @escaping ([Command]) -> Void) {
    self.concurrentRunHandler = concurrent
    self.serialRunHandler = serial
  }

  func concurrentRun(_ commands: [Command]) {
    concurrentRunHandler(commands)
  }

  func serialRun(_ commands: [Command]) {
    serialRunHandler(commands)
  }
}


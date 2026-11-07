@testable import ApplicationsFeature
@testable import CowboyCore
import CoreGraphics
import Foundation
import Testing

private struct WaitPathTrace: Sendable {
  let stream: AsyncStream<String>
  let continuation: AsyncStream<String>.Continuation

  init() {
    (stream, continuation) = AsyncStream<String>.makeStream()
  }

  func record(_ event: String) { continuation.yield(event) }

  func finish() async -> [String] {
    continuation.finish()
    var events: [String] = []
    for await event in stream { events.append(event) }
    return events
  }
}

private enum WaitPathError: Error { case reopenFailed }

private actor WaitPathStageTarget {
  private var reads = 0

  func next() -> Application.StageOrchestrator.Target? {
    reads += 1
    return reads < 3 ? nil : .init(hidden: false)
  }
}

private func waitPathCommand(identifier: String = "example.target") throws -> Command.Application {
  let fixture = #"{"application":{"bundleIdentifier":"\#(identifier)","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["waitForAppToLaunch"],"meta":{"id":"wait-parity","name":"Open","enabled":true}}"#
  return try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
}

@Test(arguments: ["reopen", "no-window", "failed-reopen", "rejected"])
@MainActor func waitPathFrontmostReopenAndFallback(route: String) async throws {
  let command = try waitPathCommand()
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let initial = UserSpace.Snapshot(apps: .init())
  let trace = WaitPathTrace()
  let wait = Operation.Wait(.testing, retries: 2, pollingInterval: .milliseconds(13), sleep: { duration in
    #expect(duration == .milliseconds(13))
    trace.record("poll sleep")
  })
  let executor = Application.Executor(.testing, wait: wait, windowOwnerNames: {
    trace.record("owners")
    return route == "no-window" ? [] : ["Target"]
  }, willExecute: { _ in trace.record("hook") })

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: target, openApplication: { url, _ in
    #expect(url.path() == "/Applications/Target.app")
    trace.record("reopen")
    if route == "failed-reopen" { throw WaitPathError.reopenFailed }
    return target
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { from, options in
        #expect(from === target)
        #expect(options == [.activateAllWindows])
        trace.record("activate")
        return route != "rejected"
      },
      isFinishedLaunching: { trace.record("finished false"); return false },
      runningApplicationsLookup: { requested in
        #expect(requested == identifier)
        trace.record("lookup")
        return [target]
      }
    )) {
      try await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        trace.record("fallback")
        return nil
      })) {
        let result = try await executor.execute(command, cgEventType: nil, snapshot: initial)
        #expect(result !== initial)
        #expect(result.apps.frontMost?.runningApplication === target)
      }
    }
  }
  var expected = ["hook", "owners", "lookup", "activate"]
  if route == "reopen" || route == "failed-reopen" { expected.append("reopen") }
  if route != "reopen" { expected.append("fallback") }
  expected += ["lookup", "finished false", "lookup", "finished false", "poll sleep", "lookup", "finished false", "poll sleep"]
  #expect(await trace.finish() == expected)
}

@Test(arguments: ["background", "electron"], [false, true])
@MainActor func waitPathBackgroundAndElectronMusic(route: String, music: Bool) async throws {
  let identifier = Core.BundleIdentifier(music ? "com.apple.Music" : "example.target")
  var command = try waitPathCommand(identifier: identifier.value)
  if route == "background" { command.modifiers.insert(.background) }
  if route == "electron" { command.application.metadata.isElectron = true }
  command.modifiers.insert(.addToStage)
  let target = Core.RunningApplication(.testing(identifier))
  let trace = WaitPathTrace()
  let wait = Operation.Wait(.testing, retries: 2, finalSleepDuration: .milliseconds(37), sleep: { duration in
    #expect(duration == .milliseconds(37))
    trace.record("final sleep")
  })
  let executor = Application.Executor(.testing, wait: wait, windowOwnerNames: {
    trace.record("unexpected owners"); return []
  }, willExecute: { _ in trace.record("hook") }, addToStage: { _ in
    trace.record("unexpected stage"); return true
  })

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, configuration in
    #expect(configuration.activates == (route == "electron"))
    trace.record("launch")
    return target
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      isFinishedLaunching: { trace.record("finished true"); return true },
      runningApplicationsLookup: { requested in
        #expect(requested == identifier)
        trace.record("lookup")
        return [target]
      }
    )) {
      let initial = UserSpace.Snapshot(apps: .init())
      let result = try await executor.execute(command, cgEventType: nil, snapshot: initial)
      #expect(result !== initial)
    }
  }
  #expect(await trace.finish() == (music ? ["hook", "launch"] : ["hook", "launch", "lookup", "finished true", "final sleep"]))
}

@Test @MainActor func waitPathSuccessfulStageOrchestrationSkipsOrdinaryWait() async throws {
  var command = try waitPathCommand()
  command.modifiers.insert(.addToStage)
  let trace = WaitPathTrace()
  let axFrame = CGRect(x: 200, y: 200, width: 400, height: 300)
  let thumbnail = CGRect(x: 10, y: 20, width: 100, height: 80)
  let pointer = CGPoint(x: 700, y: 500)
  let target = WaitPathStageTarget()
  let stage = Application.StageOrchestrator(effects: .init(
    snapshot: {
      trace.record("stage snapshot")
      return .init(frontmost: "previous", windows: [.init(id: 42, frame: thumbnail)], screen: CGRect(x: 0, y: 0, width: 1000, height: 800))
    },
    target: { _ in trace.record("stage target"); return await target.next() },
    activateTarget: { _ in trace.record("stage activation") },
    restoreFocus: { focus in #expect(focus == "previous"); trace.record("restore focus") },
    unhide: { _ in trace.record("unexpected unhide") },
    accessibilityWindows: { _ in trace.record("stage windows"); return [.init(id: 42, frame: axFrame)] },
    pointer: { trace.record("pointer"); return pointer },
    movePointer: { point in #expect(point == pointer); trace.record("restore pointer") },
    shiftClick: { point in #expect(point == CGPoint(x: 22, y: 60)); trace.record("shift click") },
    unminimizeAndRaise: { id in #expect(id == 42); trace.record("raise") },
    sleep: { duration in #expect(duration == .milliseconds(17)); trace.record("stage poll sleep") }
  ), attempts: 3, interval: .milliseconds(17))
  let wait = Operation.Wait(.testing, sleep: { _ in trace.record("unexpected wait") })
  let executor = Application.Executor(.testing, wait: wait, windowOwnerNames: {
    trace.record("owners"); return []
  }, willExecute: { _ in trace.record("hook") }, addToStage: { command in
    trace.record("stage adapter")
    return try await stage.execute(command)
  })

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    trace.record("unexpected launch"); return .init(.testing(nil))
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(runningApplicationsLookup: { _ in
      trace.record("unexpected lookup"); return []
    })) {
      let initial = UserSpace.Snapshot(apps: .init())
      let result = try await executor.execute(command, cgEventType: nil, snapshot: initial)
      #expect(result !== initial)
    }
  }
  let actual = await trace.finish()
  #expect(actual == ["hook", "owners", "stage adapter", "stage snapshot", "stage target", "stage activation", "restore focus", "stage target", "stage poll sleep", "stage target", "restore focus", "stage snapshot", "stage windows", "pointer", "shift click", "raise", "restore pointer"])
}

@Test(arguments: ["stage-declined", "finished", "missing", "running-guard", "self", "peek-no-event"])
@MainActor func waitPathOrdinaryEarlyReturnsAndDeclinedStage(route: String) async throws {
  var command = try waitPathCommand()
  if route == "stage-declined" { command.modifiers.insert(.addToStage) }
  if route == "running-guard" { command.modifiers.insert(.onlyIfNotRunning) }
  if route == "peek-no-event" { command.action = .peek }
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let initial = UserSpace.Snapshot(apps: .init())
  let trace = WaitPathTrace()
  let wait = Operation.Wait(.testing, retries: 2, pollingInterval: .milliseconds(11), sleep: { duration in
    #expect(duration == .milliseconds(11))
    trace.record("poll sleep")
  })
  let executor = Application.Executor(.testing, wait: wait, windowOwnerNames: {
    trace.record("owners"); return route == "missing" ? [] : ["Target"]
  }, willExecute: { _ in trace.record("hook") }, selfApplication: route == "self" ? .init(bundleIdentifier: identifier, open: {
    trace.record("self")
  }) : nil, addToStage: { _ in
    trace.record("stage declined"); return false
  })
  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    trace.record("launch"); return target
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      isFinishedLaunching: { trace.record("finished \(route == "finished")"); return route == "finished" },
      runningApplicationsLookup: { requested in
        #expect(requested == identifier)
        trace.record("lookup")
        return route == "missing" || route == "stage-declined" ? [] : [target]
      }
    )) {
      let result = try await executor.execute(command, cgEventType: nil, snapshot: initial)
      #expect((result === initial) == (["running-guard", "self", "peek-no-event"].contains(route)))
    }
  }
  let expected: [String]
  switch route {
  case "running-guard": expected = ["hook", "lookup"]
  case "self": expected = ["hook", "self"]
  case "peek-no-event": expected = ["hook"]
  case "missing": expected = ["hook", "owners", "launch", "lookup"]
  case "finished": expected = ["hook", "owners", "launch", "lookup", "finished true"]
  default: expected = ["hook", "owners", "stage declined", "launch", "lookup", "lookup", "poll sleep", "lookup", "poll sleep"]
  }
  let actual = await trace.finish()
  #expect(actual == expected)
}

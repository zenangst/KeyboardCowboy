@testable import ApplicationsFeature
@testable import CowboyCore
import Foundation
import Testing

private struct OrdinaryWaitTrace: Sendable {
  let stream: AsyncStream<String>
  let continuation: AsyncStream<String>.Continuation

  init() {
    (stream, continuation) = AsyncStream.makeStream()
  }

  func record(_ event: String) { continuation.yield(event) }

  func finish() async -> [String] {
    continuation.finish()
    var events: [String] = []
    for await event in stream { events.append(event) }
    return events
  }
}

private enum OrdinaryOpenFailure: Error { case launch }

private func ordinaryWaitCommand() throws -> Command.Application {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["waitForAppToLaunch"],"meta":{"id":"wait-transition","name":"Open","enabled":true}}"#
  return try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
}

@Test(arguments: ["reopen", "fallback", "post-launch-rejected"])
@MainActor func ordinaryOpenWaitsUntilLaunchingFinishes(route: String) async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let frontmost = route == "post-launch-rejected"
    ? Core.RunningApplication(.testing(.init("example.other"))) : target
  let trace = OrdinaryWaitTrace()

  // The synchronous finished-launching callback cannot await an actor. A bounded
  // stream supplies two unfinished reads before subsequent reads report finished.
  let (unfinishedReads, readContinuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingOldest(2))
  let wait = Operation.Wait(.testing, retries: 3, finalSleepDuration: .milliseconds(37),
                            pollingInterval: .milliseconds(11), sleep: { duration in
    if duration == .milliseconds(11) { trace.record("poll sleep") }
    else if duration == .milliseconds(37) { trace.record("settle sleep") }
    else { trace.record("unexpected sleep \(duration)") }
  })
  let executor = Application.Executor(.testing, wait: wait, windowOwnerNames: {
    trace.record("owners")
    return route == "fallback" ? [] : ["Target"]
  })

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost, openApplication: { url, _ in
    #expect(url.path() == "/Applications/Target.app")
    trace.record(route == "post-launch-rejected" ? "launch" : "reopen")
    return target
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { from, options in
        #expect(from === frontmost)
        #expect(options == (route == "post-launch-rejected" ? [] : [.activateAllWindows]))
        trace.record("activate")
        return route != "post-launch-rejected"
      },
      isFinishedLaunching: {
        switch readContinuation.yield(()) {
        case .enqueued:
          trace.record("unfinished")
          return false
        case .dropped:
          trace.record("finished")
          return true
        case .terminated:
          trace.record("unexpected terminated script")
          return false
        @unknown default:
          trace.record("unexpected script result")
          return false
        }
      },
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
        let initial = UserSpace.Snapshot(apps: .init())
        let result = try await executor.execute(try ordinaryWaitCommand(), cgEventType: nil, snapshot: initial)
        #expect(result !== initial)
        #expect(result.apps.frontMost?.runningApplication === frontmost)
      }
    }
  }
  readContinuation.finish()
  var readCount = 0
  for await _ in unfinishedReads { readCount += 1 }
  #expect(readCount == 2)

  let opening: [String]
  switch route {
  case "reopen": opening = ["owners", "lookup", "activate", "reopen"]
  case "fallback": opening = ["owners", "lookup", "activate", "fallback"]
  default: opening = ["owners", "launch", "lookup", "activate"]
  }
  #expect(await trace.finish() == opening + [
    "lookup", "unfinished", // Tail-wait eligibility check.
    "lookup", "unfinished", "poll sleep", "lookup", "finished", "settle sleep",
  ])
}

@Test(arguments: ["launch", "reopen-fallback", "missing-fallback"])
@MainActor func ordinaryOpenFailuresPreventTailWait(route: String) async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let frontmost = route == "launch" ? Core.RunningApplication(.testing(.init("example.other"))) : target
  let trace = OrdinaryWaitTrace()
  let wait = Operation.Wait(.testing, sleep: { _ in trace.record("unexpected wait") })
  let executor = Application.Executor(.testing, wait: wait, windowOwnerNames: {
    trace.record("owners")
    return ["Target"]
  })

  await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost, openApplication: { _, _ in
    trace.record(route == "launch" ? "launch" : "reopen")
    throw OrdinaryOpenFailure.launch
  })) {
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in trace.record("activate"); return true },
      isFinishedLaunching: { trace.record("unexpected finished check"); return false },
      runningApplicationsLookup: { requested in
        #expect(requested == identifier)
        trace.record("lookup")
        return route == "missing-fallback" ? [] : [target]
      }
    )) {
      await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        trace.record("fallback")
        return NSError(domain: "ordinary-open-test", code: 73)
      })) {
        do {
          _ = try await executor.execute(try ordinaryWaitCommand(), cgEventType: nil, snapshot: .init(apps: .init()))
          Issue.record("Expected ordinary open to fail")
        } catch OrdinaryOpenFailure.launch {
          #expect(route == "launch")
        } catch Core.NSAppleScript.Error.unableToExecute(let error) {
          #expect(route != "launch")
          #expect((error as NSError).domain == "com.zenangst.KeyboardCowboy.AppleScriptPlugin")
          #expect((error as NSError).code == 73)
        } catch {
          Issue.record("Unexpected error: \(error)")
        }
      }
    }
  }
  let expected: [String]
  switch route {
  case "launch": expected = ["owners", "launch"]
  case "reopen-fallback": expected = ["owners", "lookup", "activate", "reopen", "fallback"]
  default: expected = ["owners", "lookup", "fallback"]
  }
  #expect(await trace.finish() == expected)
}

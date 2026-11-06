@testable import ApplicationsFeature
@testable import CowboyCore
import System
import Testing
import Foundation

private enum ExecutorLaunchError: Error {
  case failed
}

private enum TestWaitError: Error {
  case reached
}

private actor OpenTrace {
  private(set) var events: [String] = []
  func record(_ event: String) { events.append(event) }
}

@Test @MainActor func frontmostAppWithTrackedWindowReopens() async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let trace = OpenTrace()
  let executor = Application.Executor(.testing, windowOwnerNames: {
    await trace.record("owners")
    return ["Target"]
  })

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: target, openApplication: { url, _ in
    #expect(url.path() == "/Applications/Target.app")
    await trace.record("reopen")
    return target
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in true }, runningApplications: [target]
    )) {
      try await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        Issue.record("Unexpected fallback for successful reopen")
        return nil
      })) {
        _ = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
      }
    }
  }
  #expect(await trace.events == ["owners", "reopen"])
}

@Test(arguments: [false, true]) @MainActor func frontmostNoWindowOrFailedReopenUsesFallback(hasWindow: Bool) async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let trace = OpenTrace()
  let executor = Application.Executor(.testing, windowOwnerNames: {
    await trace.record("owners")
    return hasWindow ? ["Target"] : ["Other"]
  })

  await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: target, openApplication: { _, _ in
    await trace.record("reopen")
    throw ExecutorLaunchError.failed
  })) {
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in true }, runningApplications: [target]
    )) {
      await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        NSError(domain: "test", code: 77)
      })) {
        do {
          _ = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
          Issue.record("Expected fallback failure")
        } catch Core.NSAppleScript.Error.unableToExecute(let error) {
          #expect((error as NSError).code == 77)
        } catch {
          Issue.record("Unexpected error: \(error)")
        }
      }
    }
  }
  #expect(await trace.events == (hasWindow ? ["owners", "reopen"] : ["owners"]))
}

@Test @MainActor func cancelledReopenDoesNotRunFallback() async throws {
  let target = Core.RunningApplication(.testing(.init("example.target")))
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let executor = Application.Executor(.testing, windowOwnerNames: { ["Target"] })

  await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: target, openApplication: { _, _ in
    throw CancellationError()
  })) {
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in true }, runningApplications: [target]
    )) {
      await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        Issue.record("Cancelled reopen must not trigger fallback")
        return nil
      })) {
        await #expect(throws: CancellationError.self) {
          try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
        }
      }
    }
  }
}

@Test(arguments: [(true, true), (false, true), (false, false)])
@MainActor func nonFrontmostLaunchActivatesAccordingToWindowState(hasWindow: Bool, hasFrontmost: Bool) async throws {
  let target = Core.RunningApplication(.testing(.init("example.target")))
  let frontmost = Core.RunningApplication(.testing(.init("example.other")))
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let trace = OpenTrace()
  let executor = Application.Executor(.testing, windowOwnerNames: {
    await trace.record("owners")
    return hasWindow ? ["Target"] : ["Other"]
  })

  try await confirmation("Expected one activation") { confirmed in
    try await Core.Workspace.Testing.$mock.withValue(.init(
      frontmostApplication: hasFrontmost ? frontmost : nil,
      openApplication: { _, _ in await trace.record("launch"); return target }
    )) {
      try await Core.RunningApplication.Testing.$mock.withValue(.init(
        activate: { options in
          #expect(!hasFrontmost)
          #expect(options == [.activateAllWindows])
          confirmed()
          return false
        },
        activateFrom: { from, options in
          #expect(from === frontmost)
          #expect(options == (hasWindow ? [] : [.activateAllWindows]))
          confirmed()
          return false
        },
        runningApplications: [target]
      )) {
        _ = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
      }
    }
  }
  #expect(await trace.events == ["owners", "launch"])
}

@Test @MainActor func nonFrontmostMissingTargetSkipsWait() async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["waitForAppToLaunch"],"meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let trace = OpenTrace()
  let wait = Operation.Wait(.testing, sleep: { _ in Issue.record("Missing target should skip tail wait") })
  let executor = Application.Executor(.testing, wait: wait, windowOwnerNames: { [] })

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    await trace.record("launch")
    return .init(.testing(nil))
  })) {
    _ = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
  }
  #expect(await trace.events == ["launch"])
}

@Test(arguments: [false, true]) @MainActor func backgroundAndElectronBypassWindowOrchestration(electron: Bool) async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  var command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  if electron {
    command.application.metadata.isElectron = true
  } else {
    command.modifiers.insert(.background)
  }
  let snapshot = UserSpace.Snapshot(apps: .init())
  let trace = OpenTrace()
  let wait = Operation.Wait(.testing, retries: 0)
  let executor = Application.Executor(.testing, wait: wait, windowOwnerNames: {
    Issue.record("Background and Electron routes must skip window lookup")
    return []
  })

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, configuration in
    #expect(configuration.activates == electron)
    await trace.record("launch")
    return .init(.testing(nil))
  })) {
    _ = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
  }
  #expect(await trace.events == ["launch"])
}

@Test @MainActor func waitModifierPollsAfterOrdinaryLaunch() async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["waitForAppToLaunch"],"meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let trace = OpenTrace()
  let wait = Operation.Wait(.testing, sleep: { _ in
    await trace.record("wait")
    throw TestWaitError.reached
  })

  await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    await trace.record("launch")
    return Core.RunningApplication(.testing(nil))
  })) {
    await #expect(throws: TestWaitError.reached) {
      try await Application.Executor(.testing, wait: wait).execute(command, cgEventType: nil, snapshot: snapshot)
    }
  }
  #expect(await trace.events == ["launch", "wait"])
}

@Test @MainActor func waitModifierSkipsAlreadyFinishedApplication() async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["waitForAppToLaunch"],"meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let trace = OpenTrace()
  let wait = Operation.Wait(.testing, sleep: { _ in Issue.record("A finished app must not be polled") })

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    await trace.record("launch")
    return target
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      isFinishedLaunching: { true }, runningApplications: [target]
    )) {
      _ = try await Application.Executor(.testing, wait: wait).execute(command, cgEventType: nil, snapshot: snapshot)
    }
  }
  #expect(await trace.events == ["launch"])
}

@Test(arguments: [true, false]) @MainActor func waitModifierFollowsActivationAndFallback(activationSucceeds: Bool) async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["waitForAppToLaunch"],"meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let wait = Operation.Wait(.testing, sleep: { _ in throw TestWaitError.reached })

  await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: target)) {
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in activationSucceeds },
      isFinishedLaunching: { false },
      runningApplications: [target]
    )) {
      await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        if activationSucceeds { Issue.record("Unexpected activation fallback") }
        return nil
      })) {
        await #expect(throws: TestWaitError.reached) {
          try await Application.Executor(.testing, wait: wait).execute(command, cgEventType: nil, snapshot: snapshot)
        }
      }
    }
  }
}

@Test(arguments: [false, true]) @MainActor func waitTimeoutContinuesWithoutRepeatingWait(background: Bool) async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["waitForAppToLaunch"],"meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  var command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  if background { command.modifiers.insert(.background) }
  let snapshot = UserSpace.Snapshot(apps: .init())
  let trace = OpenTrace()
  let wait = Operation.Wait(.testing, retries: 1, sleep: { _ in await trace.record("wait") })

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    await trace.record("launch")
    return .init(.testing(nil))
  })) {
    _ = try await Application.Executor(.testing, wait: wait).execute(command, cgEventType: nil, snapshot: snapshot)
  }
  #expect(await trace.events == ["launch", "wait"])
}

private actor LaunchEvents {
  private(set) var count = 0
  func record() { count += 1 }
}

@Test @MainActor func cancellationBeforeEffectsPreventsHideAndUnhide() async throws {
  let frontmostID = Core.BundleIdentifier("example.frontmost")
  let targetID = Core.BundleIdentifier("example.target")
  let frontmost = Core.RunningApplication(.testing(frontmostID))
  let target = Core.RunningApplication(.testing(targetID))
  let snapshot = UserSpace.Snapshot(apps: .init(
    frontMost: .init(bundleIdentifier: frontmostID, runningApplication: frontmost)))

  for action in ["hide", "unhide"] {
    let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"\#(action)","meta":{"id":"saved-command","name":"Target","enabled":true}}"#
    let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
    let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
      group.addTask {
        await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost)) {
          await Core.RunningApplication.Testing.$mock.withValue(.init(
            activate: { _ in withUnsafeCurrentTask { $0?.cancel() }; return true },
            runningApplicationsLookup: { _ in
              if action == "unhide" { withUnsafeCurrentTask { $0?.cancel() } }
              return [target]
            },
            onHide: { _ in Issue.record("Hide ran after cancellation"); return true },
            onUnhide: { _ in Issue.record("Unhide ran after cancellation"); return true }
          )) {
            do {
              _ = try await Application.Executor(.testing).execute(command, cgEventType: nil, snapshot: snapshot)
              return false
            } catch is CancellationError {
              return true
            } catch {
              return false
            }
          }
        }
      }
      return await group.next() ?? false
    }
    #expect(cancelled, "Expected cancellation for \(action)")
  }
}

@Test @MainActor func cancelledExecutorDoesNotLookUpOrTerminate() async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"close","meta":{"id":"saved-command","name":"Close","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      withUnsafeCurrentTask { $0?.cancel() }
      return await Core.RunningApplication.Testing.$mock.withValue(.init(
        runningApplicationsLookup: { _ in
          Issue.record("A cancelled command must not look up an application")
          return []
        }
      )) {
        do {
          _ = try await Application.Executor(.testing).execute(command, cgEventType: nil, snapshot: snapshot)
          return false
        } catch is CancellationError {
          return true
        } catch {
          return false
        }
      }
    }
    return await group.next() ?? false
  }
  #expect(cancelled)
}

@Test @MainActor func cancellationAfterLaunchPreventsWaitLookup() async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["background"],"meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let events = LaunchEvents()
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      await Core.RunningApplication.Testing.$mock.withValue(.init(
        runningApplicationsLookup: { _ in
          Issue.record("A cancelled launch must not start polling")
          return []
        }
      )) {
        await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
          await events.record()
          withUnsafeCurrentTask { $0?.cancel() }
          return Core.RunningApplication(.testing(nil))
        })) {
          do {
            _ = try await Application.Executor(.testing).execute(command, cgEventType: nil, snapshot: snapshot)
            return false
          } catch is CancellationError {
            return true
          } catch {
            return false
          }
        }
      }
    }
    return await group.next() ?? false
  }
  #expect(cancelled)
  #expect(await events.count == 1)
}

@Test @MainActor func executorPropagatesTerminationFailure() async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"close","meta":{"id":"saved-command","name":"Close","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())

  await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplications: [Core.RunningApplication(.testing(identifier))],
    terminate: false
  )) {
    await #expect(throws: Application.Executor.ExecutionError.failedToTerminate(identifier)) {
      try await Application.Executor(.testing).execute(command, cgEventType: nil, snapshot: snapshot)
    }
  }
  #expect(snapshot.apps.frontMost == nil)
}

@Test @MainActor func executorPropagatesLaunchFailure() async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let initial = UserSpace.Snapshot(apps: .init())
  let executor = Application.Executor(.testing)

  await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    await Task.yield()
    throw ExecutorLaunchError.failed
  })) {
    await #expect(throws: ExecutorLaunchError.failed) {
      try await executor.execute(command, cgEventType: nil, snapshot: initial)
    }
  }
  #expect(initial.apps.frontMost == nil)
  #expect(initial.apps.previous == nil)
}

@Test @MainActor func executorReturnsRefreshedSnapshotForConsecutiveCommands() async throws {
  let first = Core.RunningApplication(.testing(.init("example.first")))
  let second = Core.RunningApplication(.testing(.init("example.second")))
  let initial = UserSpace.Snapshot(apps: .init(
    frontMost: .init(bundleIdentifier: .init("example.first"), runningApplication: first)))
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"close","meta":{"id":"saved-command","name":"Close","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let executor = Application.Executor(.testing)

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: second)) {
    let updated = try await executor.execute(command, cgEventType: nil, snapshot: initial)
    #expect(updated.apps.frontMost?.runningApplication === second)
    #expect(updated.apps.previous?.runningApplication === first)
    let next = try await executor.execute(command, cgEventType: nil, snapshot: updated)
    #expect(next.apps.frontMost?.runningApplication === second)
    #expect(next.apps.previous?.runningApplication === first)
    #expect(initial.apps.frontMost?.runningApplication === first)
  }
}

@Test @MainActor func executorRefreshesOpenButNotPeek() async throws {
  let first = Core.RunningApplication(.testing(.init("example.first")))
  let second = Core.RunningApplication(.testing(.init("example.second")))
  let initial = UserSpace.Snapshot(apps: .init(
    frontMost: .init(bundleIdentifier: .init("example.first"), runningApplication: first)))
  let fixture = #"{"application":{"bundleIdentifier":"example.second","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  var command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let executor = Application.Executor(.testing)

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: second)) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in true }, runningApplications: [second]
    )) {
      let updated = try await executor.execute(command, cgEventType: nil, snapshot: initial)
      #expect(updated.apps.frontMost?.runningApplication === second)
      #expect(updated.apps.previous?.runningApplication === first)
      command.action = .peek
      let untouched = try await executor.execute(command, cgEventType: nil, snapshot: initial)
      #expect(untouched === initial)
    }
  }
}

@Test @MainActor func executorFallsBackAfterFrontmostActivationRejection() async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: target)) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in false }, runningApplications: [target]
    )) {
      try await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        nil
      })) {
        _ = try await Application.Executor(.testing).execute(command, cgEventType: nil, snapshot: snapshot)
      }
    }
  }
}

@Test @MainActor func executorPropagatesBringToFrontFailure() async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())

  await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: target)) {
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in false }, runningApplications: [target]
    )) {
      await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        NSError(domain: "test", code: 42)
      })) {
        do {
          _ = try await Application.Executor(.testing).execute(command, cgEventType: nil, snapshot: snapshot)
          Issue.record("Expected AppleScript failure")
        } catch Core.NSAppleScript.Error.unableToExecute(let error) {
          #expect((error as NSError).code == 42)
        } catch {
          Issue.record("Unexpected error: \(error)")
        }
      }
    }
  }
}

@Test @MainActor func cancelledActivationIsNotReportedAsFailure() async throws {
  let target = Core.RunningApplication(.testing(.init("example.target")))
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: target)) {
        await Core.RunningApplication.Testing.$mock.withValue(.init(
          activateFrom: { _, _ in withUnsafeCurrentTask { $0?.cancel() }; return false },
          runningApplications: [target]
        )) {
          await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
            Issue.record("Cancellation must not trigger activation fallback")
            return nil
          })) {
            do {
              _ = try await Application.Executor(.testing).execute(command, cgEventType: nil, snapshot: snapshot)
              return false
            } catch is CancellationError {
              return true
            } catch {
              return false
            }
          }
        }
      }
    }
    return await group.next() ?? false
  }
  #expect(cancelled)
}

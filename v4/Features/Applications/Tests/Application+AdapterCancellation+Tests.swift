import UserSpace
import Commands
@testable import ApplicationsFeature
@testable import CowboyCore
import CoreGraphics
import Foundation
import Testing

private func adapterCancellationCommand(_ action: String, modifiers: String = "") throws -> Command.Application {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"\#(action)","modifiers":[\#(modifiers)],"meta":{"id":"saved-command","name":"Target","enabled":true}}"#
  return try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
}

// The host adapter deliberately ignores cancellation until the caller releases it.
private actor AdapterGate {
  private var continuation: CheckedContinuation<Void, Never>?
  private var arrival: CheckedContinuation<Void, Never>?

  func suspend() async {
    await withCheckedContinuation { continuation in
      self.continuation = continuation
      arrival?.resume()
      arrival = nil
    }
  }

  func waitForArrival() async {
    if continuation != nil { return }
    await withCheckedContinuation { arrival = $0 }
  }

  func release() {
    continuation?.resume()
    continuation = nil
  }
}

private func cancelWhileSuspended(_ gate: AdapterGate, operation: @escaping @Sendable () async throws -> Void) async {
  await withTaskGroup(of: Bool.self) { group in
    group.addTask {
      do {
        try await operation()
        return false
      } catch is CancellationError {
        return true
      } catch {
        Issue.record("Unexpected error: \(error)")
        return false
      }
    }
    await gate.waitForArrival()
    group.cancelAll()
    await gate.release()
    #expect(await group.next() == true)
  }
}

@Test @MainActor func callerCancellationWhileWillExecuteIsSuspendedPreventsGuard() async throws {
  let command = try adapterCancellationCommand("open", modifiers: #""onlyIfNotRunning""#)
  let snapshot = UserSpace.Snapshot(apps: .init())
  let gate = AdapterGate()
  let executor = Application.Executor(.testing, willExecute: { _ in await gate.suspend() })

  await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplicationsLookup: { _ in Issue.record("Cancelled hook must prevent lookup"); return [] }
  )) {
    await cancelWhileSuspended(gate) {
      _ = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
    }
  }
}

@Test(arguments: [false, true]) @MainActor func callerCancellationWhilePeekReleaseIsSuspendedPreventsReleaseEffects(openPrevious: Bool) async throws {
  let command = try adapterCancellationCommand("peek")
  let previous = try adapterCancellationCommand("open")
  let snapshot = UserSpace.Snapshot(apps: .init())
  let gate = AdapterGate()
  let executor = Application.Executor(.testing, windowOwnerNames: {
    Issue.record("Cancelled release must not query window owners")
    return []
  }, peekRelease: { _ in
    await gate.suspend()
    return openPrevious ? .open(previous) : .hide
  })

  await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    Issue.record("Cancelled release must not launch")
    return .init(.testing(nil))
  })) {
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { _ in Issue.record("Cancelled release must not look up applications"); return [] },
      onHide: { _ in Issue.record("Cancelled release must not hide"); return true }
    )) {
      await cancelWhileSuspended(gate) {
        _ = try await executor.execute(command, cgEventType: .keyUp, snapshot: snapshot)
      }
    }
  }
}

@Test(arguments: [false, true]) @MainActor func callerCancellationWhileWindowOwnersAreSuspendedPreventsOpen(frontmost: Bool) async throws {
  let command = try adapterCancellationCommand("open")
  let snapshot = UserSpace.Snapshot(apps: .init())
  let target = Core.RunningApplication(.testing(.init("example.target")))
  let gate = AdapterGate()
  let executor = Application.Executor(.testing, windowOwnerNames: {
    await gate.suspend()
    return ["Target"]
  })

  await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost ? target : nil, openApplication: { _, _ in
    Issue.record("Cancelled owner lookup must not launch")
    return target
  })) {
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in Issue.record("Cancelled owner lookup must not activate"); return true },
      runningApplicationsLookup: { _ in Issue.record("Cancelled owner lookup must not look up applications"); return [target] }
    )) {
      await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        Issue.record("Cancelled owner lookup must not invoke fallback")
        return nil
      })) {
        await cancelWhileSuspended(gate) {
          _ = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
        }
      }
    }
  }
}

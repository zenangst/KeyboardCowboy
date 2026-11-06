@testable import ApplicationsFeature
@testable import CowboyCore
import System
import Testing
import Foundation
import os

private enum ExecutorLaunchError: Error {
  case failed
}

@Test @MainActor func cancelledExecutorDoesNotLookUpOrTerminate() async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"close","meta":{"id":"saved-command","name":"Close","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let lookups = OSAllocatedUnfairLock(initialState: 0)
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      withUnsafeCurrentTask { $0?.cancel() }
      return await Core.RunningApplication.Testing.$mock.withValue(.init(
        runningApplicationsLookup: { _ in lookups.withLock { $0 += 1 }; return [] }
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
  #expect(lookups.withLock { $0 } == 0)
}

@Test @MainActor func cancellationAfterLaunchPreventsWaitLookup() async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["background"],"meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let calls = OSAllocatedUnfairLock(initialState: [String]())
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      await Core.RunningApplication.Testing.$mock.withValue(.init(
        runningApplicationsLookup: { _ in calls.withLock { $0.append("lookup") }; return [] }
      )) {
        await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
          calls.withLock { $0.append("launch") }
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
  #expect(calls.withLock { $0 } == ["launch"])
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
    let updated = try await executor.execute(command, cgEventType: nil, snapshot: initial)
    #expect(updated.apps.frontMost?.runningApplication === second)
    #expect(updated.apps.previous?.runningApplication === first)
    command.action = .peek
    let untouched = try await executor.execute(command, cgEventType: nil, snapshot: initial)
    #expect(untouched === initial)
  }
}

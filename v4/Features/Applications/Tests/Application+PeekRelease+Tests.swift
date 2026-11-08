import UserSpace
import Commands
@testable import ApplicationsFeature
@testable import CowboyCore
import CoreGraphics
import Foundation
import Testing

private func peekCommand(_ identifier: String = "example.target", action: String = "peek") throws -> Command.Application {
  let fixture = #"{"application":{"bundleIdentifier":"\#(identifier)","bundleName":"Target","path":"/Applications/Target.app"},"action":"\#(action)","meta":{"id":"saved-command","name":"Peek","enabled":true}}"#
  return try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
}

@Test @MainActor func peekPressOpensWithoutConsultingReleaseHandler() async throws {
  let command = try peekCommand()
  let snapshot = UserSpace.Snapshot(apps: .init())
  let (events, continuation) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, peekRelease: { _ in
    Issue.record("Press must not consult release handler")
    return .none
  })

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    continuation.yield("launch")
    return .init(.testing(nil))
  })) {
    let result = try await executor.execute(command, cgEventType: .keyDown, snapshot: snapshot)
    #expect(result === snapshot)
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["launch"])
}

@Test @MainActor func peekReleaseDefaultsToHidingTarget() async throws {
  let command = try peekCommand()
  let target = Core.RunningApplication(.testing(.init("example.target")))
  let snapshot = UserSpace.Snapshot(apps: .init())

  try await confirmation("Expected one target hide") { hidden in
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplications: [target], onHide: { application in
        #expect(application === target)
        hidden()
        return true
      }
    )) {
      let result = try await Application.Executor(.testing).execute(command, cgEventType: .keyUp, snapshot: snapshot)
      #expect(result === snapshot)
    }
  }
}

@Test @MainActor func peekReleaseCanOpenHostProvidedPreviousApplication() async throws {
  let command = try peekCommand()
  var previous = try peekCommand("example.previous", action: "open")
  previous.application = .init(bundleIdentifier: "example.previous", bundleName: "Previous", path: "/Applications/Previous.app")
  let previousCommand = previous
  let snapshot = UserSpace.Snapshot(apps: .init())
  let (events, continuation) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, peekRelease: { received in
    #expect(received.application.bundleIdentifier == "example.target")
    continuation.yield("release")
    return .open(previousCommand)
  })

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { url, _ in
    #expect(url.path() == "/Applications/Previous.app")
    continuation.yield("previous")
    return .init(.testing(nil))
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      onHide: { _ in Issue.record("Previous-app release must not hide the peeked app"); return false }
    )) {
      let result = try await executor.execute(command, cgEventType: .keyUp, snapshot: snapshot)
      #expect(result === snapshot)
    }
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["release", "previous"])
}

@Test @MainActor func peekReleaseWithoutPreviousApplicationIsNoOp() async throws {
  let command = try peekCommand()
  let snapshot = UserSpace.Snapshot(apps: .init())
  let executor = Application.Executor(.testing, peekRelease: { _ in .none })
  try await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplicationsLookup: { _ in Issue.record("No-op release must not perform lookup"); return [] }
  )) {
    let result = try await executor.execute(command, cgEventType: .keyUp, snapshot: snapshot)
    #expect(result === snapshot)
  }
}

@Test @MainActor func peekPolicyOpensPreviousWithoutInheritingItsModifiers() async throws {
  let command = try peekCommand()
  var previous = try peekCommand("example.previous", action: "hide")
  previous.application = .init(bundleIdentifier: "example.previous", bundleName: "Previous", path: "/Applications/Previous.app")
  previous.modifiers = [.background, .hidden, .onlyIfNotRunning, .waitForAppToLaunch]
  let suppliedPrevious = previous
  let snapshot = UserSpace.Snapshot(apps: .init())
  let executor = Application.Executor(.testing, peekRelease: { _ in
    .resolve(stageManagerEnabled: true, previous: suppliedPrevious)
  })

  try await confirmation("Expected previous application to open") { opened in
    try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { url, configuration in
      #expect(url.path() == "/Applications/Previous.app")
      #expect(configuration.activates)
      #expect(!configuration.hides)
      opened()
      return .init(.testing(nil))
    })) {
      let result = try await executor.execute(command, cgEventType: .keyUp, snapshot: snapshot)
      #expect(result === snapshot)
    }
  }
}

@Test @MainActor func cancelledPeekReleaseDoesNotPerformEffects() async throws {
  let command = try peekCommand()
  let snapshot = UserSpace.Snapshot(apps: .init())
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      await Core.RunningApplication.Testing.$mock.withValue(.init(
        runningApplicationsLookup: { _ in Issue.record("Cancelled release must not perform lookup"); return [] }
      )) {
        do {
          _ = try await Application.Executor(.testing, peekRelease: { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return .hide
          }).execute(command, cgEventType: .keyUp, snapshot: snapshot)
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

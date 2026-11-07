@testable import ApplicationsFeature
@testable import CowboyCore
import Foundation
import Testing

private enum StageTestError: Error { case failure, waitReached }

private actor StageGate {
  private var continuation: CheckedContinuation<Void, Never>?
  private var released = false

  func wait() async {
    guard !released else { return }
    await withCheckedContinuation { continuation = $0 }
  }

  func release() {
    released = true
    continuation?.resume()
    continuation = nil
  }
}

private func stageCommand() throws -> Command.Application {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","modifiers":["addToStage","waitForAppToLaunch"],"meta":{"id":"saved-command","name":"Open","enabled":true}}"#
  return try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
}

@Test(arguments: [false, true]) @MainActor func addToStageSuccessAndFallback(added: Bool) async throws {
  let command = try stageCommand()
  let snapshot = UserSpace.Snapshot(apps: .init())
  let (events, continuation) = AsyncStream<String>.makeStream()
  let wait = Operation.Wait(.testing, sleep: { _ in Issue.record("These routes must not poll") })
  let executor = Application.Executor(.testing, wait: wait, windowOwnerNames: {
    continuation.yield("owners")
    return []
  }, addToStage: { received in
    #expect(received.application.bundleIdentifier == "example.target")
    continuation.yield("stage")
    return added
  })

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    continuation.yield("launch")
    return .init(.testing(nil))
  })) {
    let result = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
    #expect(result !== snapshot)
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == (added ? ["owners", "stage"] : ["owners", "stage", "launch"]))
}

@Test @MainActor func handledStageRefreshesSnapshot() async throws {
  let command = try stageCommand()
  let old = Core.RunningApplication(.testing(.init("example.old")))
  let current = Core.RunningApplication(.testing(.init("example.current")))
  let snapshot = UserSpace.Snapshot(apps: .init(
    frontMost: .init(bundleIdentifier: .init("example.old"), runningApplication: old)))
  let executor = Application.Executor(.testing, addToStage: { _ in true })

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: current, openApplication: { _, _ in
    Issue.record("Handled stage must not launch")
    return .init(.testing(nil))
  })) {
    let result = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
    #expect(result !== snapshot)
    #expect(result.apps.frontMost?.runningApplication === current)
    #expect(result.apps.previous?.runningApplication === old)
  }
}

@Test @MainActor func declinedStagePreservesOrdinaryTailWait() async throws {
  let command = try stageCommand()
  let snapshot = UserSpace.Snapshot(apps: .init())
  let (events, continuation) = AsyncStream<String>.makeStream()
  let wait = Operation.Wait(.testing, sleep: { _ in
    continuation.yield("wait")
    throw StageTestError.waitReached
  })
  let executor = Application.Executor(.testing, wait: wait, windowOwnerNames: { ["Target"] }, addToStage: { _ in
    continuation.yield("stage")
    return false
  })

  await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    continuation.yield("launch")
    return .init(.testing(nil))
  })) {
    await #expect(throws: StageTestError.waitReached) {
      try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
    }
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["stage", "launch", "wait"])
}

@Test @MainActor func cancellationWhileStageAdapterSuspendsPreventsFallback() async throws {
  let command = try stageCommand()
  let snapshot = UserSpace.Snapshot(apps: .init())
  let gate = StageGate()
  let (events, continuation) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, addToStage: { _ in
    continuation.yield("stage")
    await gate.wait()
    return false
  })

  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
        Issue.record("Cancelled stage operation must not launch")
        return .init(.testing(nil))
      })) {
        do {
          _ = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
          return false
        } catch is CancellationError {
          return true
        } catch {
          return false
        }
      }
    }
    var iterator = events.makeAsyncIterator()
    #expect(await iterator.next() == "stage")
    group.cancelAll()
    await gate.release()
    return await group.next() ?? false
  }
  continuation.finish()
  #expect(cancelled)
}

@Test @MainActor func addToStageFailureDoesNotLaunch() async throws {
  let command = try stageCommand()
  let snapshot = UserSpace.Snapshot(apps: .init())
  let executor = Application.Executor(.testing, addToStage: { _ in throw StageTestError.failure })

  await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    Issue.record("Stage errors must not trigger ordinary launch")
    return .init(.testing(nil))
  })) {
    await #expect(throws: StageTestError.failure) {
      try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
    }
  }
}

@Test(arguments: [false, true]) @MainActor func missingAdapterOrModifierUsesOrdinaryLaunch(hasAdapter: Bool) async throws {
  var command = try stageCommand()
  if hasAdapter { command.modifiers.remove(.addToStage) }
  let snapshot = UserSpace.Snapshot(apps: .init())
  let unexpectedAdapter: @Sendable (Command.Application) async throws -> Bool = { _ in
    Issue.record("Stage adapter requires the add-to-stage modifier")
    return true
  }
  let adapter = hasAdapter ? unexpectedAdapter : nil
  let executor = Application.Executor(.testing, wait: .init(.testing, retries: 0), addToStage: adapter)

  try await confirmation("Expected ordinary launch") { launched in
    try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
      launched()
      return .init(.testing(nil))
    })) {
      _ = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
    }
  }
}

@Test @MainActor func addToStageCancellationTakesPrecedenceOverFailure() async throws {
  let command = try stageCommand()
  let snapshot = UserSpace.Snapshot(apps: .init())
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
        Issue.record("Cancelled stage operation must not launch")
        return .init(.testing(nil))
      })) {
        do {
          _ = try await Application.Executor(.testing, addToStage: { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            throw StageTestError.failure
          }).execute(command, cgEventType: nil, snapshot: snapshot)
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

@Test(arguments: ["frontmost", "background", "electron"])
@MainActor func addToStageIsSkippedForIneligibleOpenRoutes(route: String) async throws {
  var command = try stageCommand()
  command.modifiers.remove(.waitForAppToLaunch)
  if route == "background" { command.modifiers.insert(.background) }
  if route == "electron" { command.application.metadata.isElectron = true }
  let target = Core.RunningApplication(.testing(.init("example.target")))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let wait = Operation.Wait(.testing, retries: 0)
  let executor = Application.Executor(.testing, wait: wait, addToStage: { _ in
    Issue.record("Unexpected stage attempt for \(route)")
    return true
  })

  try await Core.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: route == "frontmost" ? target : nil,
    openApplication: { _, _ in target }
  )) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in true }, runningApplications: [target]
    )) {
      _ = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
    }
  }
}

@Test(arguments: [false, true]) @MainActor func runningGuardAndSelfAppSkipStage(running: Bool) async throws {
  var command = try stageCommand()
  if running { command.modifiers.insert(.onlyIfNotRunning) }
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let (events, continuation) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, willExecute: { _ in
    continuation.yield("hook")
  }, selfApplication: .init(bundleIdentifier: identifier, open: {
    continuation.yield("self")
  }), addToStage: { _ in
    Issue.record("Running guard and self-app handling must precede stage")
    return true
  })

  try await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplicationsLookup: { _ in continuation.yield("lookup"); return [target] }
  )) {
    let result = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
    #expect(result === snapshot)
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == (running ? ["hook", "lookup"] : ["hook", "self"]))
}

@Test(arguments: [false, true]) @MainActor func peekOpenRoutesStageAdapterWithoutRefreshingSnapshot(isRelease: Bool) async throws {
  var command = try stageCommand()
  command.action = .peek
  var previous = try stageCommand()
  previous.application = .init(bundleIdentifier: "example.previous", bundleName: "Previous", path: "/Applications/Previous.app")
  let previousCommand = previous
  let snapshot = UserSpace.Snapshot(apps: .init())

  try await confirmation("Expected one stage attempt") { attempted in
    let executor = Application.Executor(.testing, peekRelease: { _ in .open(previousCommand) }, addToStage: { received in
      #expect(received.application.bundleIdentifier == (isRelease ? "example.previous" : "example.target"))
      attempted()
      return true
    })
    try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
      Issue.record("Handled peek stage must not launch")
      return .init(.testing(nil))
    })) {
      let result = try await executor.execute(command, cgEventType: isRelease ? .keyUp : .keyDown, snapshot: snapshot)
      #expect(result === snapshot)
    }
  }
}

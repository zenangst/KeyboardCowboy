import Foundation
@testable import SystemFeature
import Testing
import UserSpace

@MainActor
private func dockExecutor(_ send: @escaping @MainActor (String) throws -> Void) -> SystemCommand.Executor {
  SystemCommand.Executor(
    sendDockNotification: send,
    previousApplication: {
      Issue.record("Unexpected app history lookup")
      return (nil, UserSpace.Snapshot(apps: .init()))
    },
    openApplication: { _, _, _ in Issue.record("Unexpected application open") },
  )
}

@Test(arguments: [
  ("missionControl", "com.apple.expose.awake"),
  ("applicationWindows", "com.apple.expose.front.awake"),
  ("showDesktop", "com.apple.showdesktop.awake"),
])
@MainActor
func dispatchesPersistedAction(rawValue: String, notification: String) async throws {
  let data = Data("\"\(rawValue)\"".utf8)
  let action = try JSONDecoder().decode(SystemCommand.Action.self, from: data)
  var calls: [String] = []
  let executor = dockExecutor { calls.append($0) }

  #expect(try await executor.run(action) == .invoked)
  #expect(calls == [notification])
  #expect(try JSONEncoder().encode(action) == data)
}

@Test @MainActor
func propagatesDockError() async {
  var calls: [String] = []
  let executor = dockExecutor {
    calls.append($0)
    throw SystemCommand.ExecutionError.dockUnavailable
  }

  await #expect(throws: SystemCommand.ExecutionError.dockUnavailable) {
    try await executor.run(.showDesktop)
  }
  #expect(calls == ["com.apple.showdesktop.awake"])
}

@Test @MainActor
func cancellationPreventsInvocation() async {
  var calls: [String] = []
  let executor = dockExecutor { calls.append($0) }

  let task = Task { @MainActor in
    withUnsafeCurrentTask { $0?.cancel() }
    return try await executor.run(.missionControl)
  }

  await #expect(throws: CancellationError.self) { try await task.value }
  #expect(calls.isEmpty)
}

@Test @MainActor
func cancellationDuringInvocationDoesNotMaskCompletion() async throws {
  var calls: [String] = []
  let executor = dockExecutor {
    calls.append($0)
    withUnsafeCurrentTask { $0?.cancel() }
  }

  let task = Task { @MainActor in try await executor.run(.applicationWindows) }

  #expect(try await task.value == .invoked)
  #expect(calls == ["com.apple.expose.front.awake"])
}

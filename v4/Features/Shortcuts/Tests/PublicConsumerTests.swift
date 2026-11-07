import Foundation
import Testing
import ShortcutsFeature

// This file deliberately uses an ordinary import, as a downstream client would.
@Test func publicExecutorRejectsPrecancelledWork() async throws {
  let executor = Shortcuts.Executor()
  let task = Task {
    withUnsafeCurrentTask { $0?.cancel() }
    await #expect(throws: CancellationError.self) {
      try await executor.run("ShortcutsFeature-test-\(UUID().uuidString)", cancellation: .checkBeforeLaunch)
    }
  }
  await task.value
}

@Test func publicConsumerCanReferenceRunPolicyAndError() {
  let executor = Shortcuts.Executor()
  let run: @Sendable (String, Shortcuts.CancellationPolicy) async throws -> String? = executor.run
  let policy: Shortcuts.CancellationPolicy = .ignore
  let error: Shortcuts.ExecutionError = .executionFailed("stderr\n")
  _ = run
  _ = policy
  #expect(error == .executionFailed("stderr\n"))
}

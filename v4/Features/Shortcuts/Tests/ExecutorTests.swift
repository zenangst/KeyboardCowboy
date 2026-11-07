import Testing
@testable import ShortcutsFeature

@Test(arguments: ["My Shortcut", "日本語 ✨", "", "A7E8-1234", "--x; '$(echo hi)'\nnext"])
func preservesIdentifier(identifier: String) async throws {
  let executor = Shortcuts.Executor { $0 }
  #expect(try await executor.run(identifier, cancellation: .checkBeforeLaunch) == identifier)
}

@Test func cancellationPolicies() async throws {
  let executor = Shortcuts.Executor { $0 }
  let task = Task { () throws in
    withUnsafeCurrentTask { $0?.cancel() }
    await #expect(throws: CancellationError.self) {
      try await executor.run("name", cancellation: .checkBeforeLaunch)
    }
    #expect(try await executor.run("name", cancellation: .ignore) == "name")
  }
  try await task.value
}

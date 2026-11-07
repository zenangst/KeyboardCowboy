import Foundation
import Testing
import CowboyCore
@testable import ShortcutsFeature

private final class Calls: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [Core.Process.LaunchConfiguration] = []
  func record(_ value: Core.Process.LaunchConfiguration) {
    lock.lock(); defer { lock.unlock() }
    storage.append(value)
  }
  var values: [Core.Process.LaunchConfiguration] {
    lock.lock(); defer { lock.unlock() }
    return storage
  }
}

@Test(arguments: ["My Shortcut", "日本語 ✨", "", "A7E8-1234", "--x; '$(echo hi)'\nnext"])
func subprocessReceivesExactArguments(identifier: String) async throws {
  let calls = Calls()
  let mock = Core.Process.Mock(observeLaunch: { calls.record($0) }, readStandardOutput: { Data("output".utf8) }, readStandardError: { nil })
  try await Core.Process.Testing.$mock.withValue(mock) { () async throws in
    #expect(try await Shortcuts.Executor.testing().run(identifier, cancellation: .checkBeforeLaunch) == "output")
  }
  #expect(calls.values.count == 1)
  #expect(calls.values.first?.executableURL?.path == "/usr/bin/shortcuts")
  #expect(calls.values.first?.arguments == ["run", identifier])
  #expect(calls.values.first?.environment == nil)
  #expect(calls.values.first?.currentDirectoryURL == nil)
}

@Test(arguments: [(Data("hello".utf8) as Data?, "hello" as String?), (Data("hello\n\n".utf8), "hello\n\n"), (Data(), ""), (nil, nil), (Data([0xff]), nil)])
func successfulOutput(stdout: Data?, expected: String?) async throws {
  let mock = Core.Process.Mock(readStandardOutput: { stdout }, readStandardError: { Data("ignored".utf8) })
  try await Core.Process.Testing.$mock.withValue(mock) { () async throws in
    #expect(try await Shortcuts.Executor.testing().run("name", cancellation: .ignore) == expected)
  }
}

@Test(arguments: [(Data("error\n".utf8) as Data?, "error\n"), (Data(), ""), (nil, ""), (Data([0xff]), "")])
func failedOutput(stderr: Data?, expected: String) async {
  let mock = Core.Process.Mock(terminationStatus: 42, readStandardOutput: { Data("ignored".utf8) }, readStandardError: { stderr })
  await Core.Process.Testing.$mock.withValue(mock) {
    await #expect(throws: Shortcuts.ExecutionError.executionFailed(expected)) {
      try await Shortcuts.Executor.testing().run("name", cancellation: .ignore)
    }
  }
}

private enum SubprocessFailure: Error, Equatable { case launch, stdout, stderr }

@Test(arguments: [SubprocessFailure.launch, .stdout, .stderr])
private func subprocessErrorsPropagate(error: SubprocessFailure) async {
  let mock = Core.Process.Mock(run: { if error == .launch { throw error } }, readStandardOutput: {
    if error == .stdout { throw error }; return Data()
  }, readStandardError: {
    if error == .stderr { throw error }; return Data()
  })
  await Core.Process.Testing.$mock.withValue(mock) {
    await #expect(throws: error) { try await Shortcuts.Executor.testing().run("name", cancellation: .ignore) }
  }
}

@Test func cancellationAtSubprocessBoundary() async throws {
  let calls = Calls()
  let mock = Core.Process.Mock(observeLaunch: { calls.record($0) }, readStandardOutput: { Data("ran".utf8) }, readStandardError: { nil })
  try await Core.Process.Testing.$mock.withValue(mock) {
    let task = Task { () throws in
      withUnsafeCurrentTask { $0?.cancel() }
      await #expect(throws: CancellationError.self) {
        try await Shortcuts.Executor.testing().run("blocked", cancellation: .checkBeforeLaunch)
      }
      #expect(calls.values.isEmpty)
      #expect(try await Shortcuts.Executor.testing().run("allowed", cancellation: .ignore) == "ran")
    }
    try await task.value
  }
  #expect(calls.values.count == 1)
  #expect(calls.values.first?.arguments == ["run", "allowed"])
}

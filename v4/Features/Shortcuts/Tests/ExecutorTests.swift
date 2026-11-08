import ProcessSystem
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

@Test(arguments: ["My Shortcut", "日本語 ✨", "  shortcut with spaces  ", "", "A7E8-1234", "--x; '$(echo hi)'\nnext"])
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

private final class Events: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [String] = []
  func record(_ event: String) { lock.lock(); defer { lock.unlock() }; storage.append(event) }
  var values: [String] { lock.lock(); defer { lock.unlock() }; return storage }
}

@Test(arguments: [SubprocessFailure.launch, .stdout, .stderr])
private func subprocessErrorsPropagate(error: SubprocessFailure) async {
  let events = Events()
  let mock = Core.Process.Mock(run: { events.record("launch"); if error == .launch { throw error } }, waitUntilExit: {
    events.record("wait")
  }, observeTerminationStatus: { events.record("status") }, readStandardOutput: {
    events.record("stdout")
    if error == .stdout { throw error }; return Data()
  }, readStandardError: {
    events.record("stderr")
    if error == .stderr { throw error }; return Data()
  })
  await Core.Process.Testing.$mock.withValue(mock) {
    await #expect(throws: error) { try await Shortcuts.Executor.testing().run("name", cancellation: .ignore) }
  }
  switch error {
  case .launch: #expect(events.values == ["launch"])
  case .stdout: #expect(events.values == ["launch", "stdout", "wait"])
  case .stderr: #expect(events.values == ["launch", "stdout", "stderr", "wait"])
  }
}

@Test(arguments: [Int32(0), 42])
func statusIsReadAfterWait(status: Int32) async {
  let events = Events()
  let mock = Core.Process.Mock(run: { events.record("launch") }, waitUntilExit: { events.record("wait") }, terminationStatus: status, observeTerminationStatus: { events.record("status") }, readStandardOutput: { events.record("stdout"); return Data("out".utf8) }, readStandardError: { events.record("stderr"); return Data("err".utf8) })
  await Core.Process.Testing.$mock.withValue(mock) {
    if status == 0 {
      #expect((try? await Shortcuts.Executor.testing().run("name", cancellation: .ignore)) == "out")
    } else {
      await #expect(throws: Shortcuts.ExecutionError.executionFailed("err")) {
        try await Shortcuts.Executor.testing().run("name", cancellation: .ignore)
      }
    }
  }
  #expect(events.values == ["launch", "stdout", "stderr", "wait", "status"])
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

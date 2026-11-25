import Darwin
import Foundation
@testable import ProcessSystem
import Testing

@Test func unboundedCaptureDrainsBothStreamsAndReportsStatus() throws {
  let process = ProcessSystem.Process(.production, launchStyle: .headless("test"))
  process.executableURL = URL(filePath: "/bin/sh")
  process.arguments = ["-c", "head -c 1048576 /dev/zero & head -c 1048576 /dev/zero >&2 & wait; exit 7"]
  process.standardOutput = ProcessSystem.Pipe(.production)
  process.standardError = ProcessSystem.Pipe(.production)
  let output = try process.runAndCaptureOutputUnbounded()
  #expect(output.stdout?.count == 1_048_576)
  #expect(output.stderr?.count == 1_048_576)
  #expect(process.terminationStatus == 7)
}

@Test(arguments: ["My Shortcut", "日本語 ✨", "  padded  ", "", "A7E8-1234", "--x; '$(echo hi)'\nnext"])
func unboundedCapturePassesLiteralArgumentsToLiveChild(argument: String) throws {
  let process = ProcessSystem.Process(.production, launchStyle: .headless("test"))
  process.executableURL = URL(filePath: "/usr/bin/printf")
  process.arguments = ["%s", argument]
  process.standardOutput = ProcessSystem.Pipe(.production)
  process.standardError = ProcessSystem.Pipe(.production)

  let output = try process.runAndCaptureOutputUnbounded()
  #expect(output.stdout == (argument.isEmpty ? nil : Data(argument.utf8)))
  #expect(output.stderr == nil)
  #expect(process.terminationStatus == 0)
}

@Test func unboundedCaptureInheritsLiveEnvironment() throws {
  let key = "HOME"
  let expected = try #require(ProcessInfo.processInfo.environment[key])
  let process = ProcessSystem.Process(.production, launchStyle: .headless("test"))
  process.executableURL = URL(filePath: "/usr/bin/printenv")
  process.arguments = [key]
  process.standardOutput = ProcessSystem.Pipe(.production)
  process.standardError = ProcessSystem.Pipe(.production)

  #expect(process.environment == nil)
  let output = try process.runAndCaptureOutputUnbounded()
  #expect(output.stdout == Data((expected + "\n").utf8))
  #expect(output.stderr == nil)
  #expect(process.terminationStatus == 0)
}

@Test func unboundedCapturePropagatesLiveLaunchFailure() {
  let process = ProcessSystem.Process(.production, launchStyle: .headless("test"))
  process.executableURL = URL(filePath: "/nonexistent-keyboard-cowboy-test-\(UUID().uuidString)")
  process.standardOutput = ProcessSystem.Pipe(.production)
  process.standardError = ProcessSystem.Pipe(.production)

  #expect(throws: (any Error).self) { try process.runAndCaptureOutputUnbounded() }
}

private enum CaptureFailure: Error, Equatable { case launch, stdout, stderr }

@Test(arguments: [CaptureFailure.stdout, .stderr])
private func unboundedCaptureReapsLiveChildAndClosesPipesAfterReadFailure(failure: CaptureFailure) throws {
  let process = ProcessSystem.Process(.production, launchStyle: .headless("test"))
  let stdout = ProcessSystem.Pipe(.production)
  let stderr = ProcessSystem.Pipe(.production)
  process.executableURL = URL(filePath: "/bin/sleep")
  process.arguments = ["2"] // No descendants; bounded even if termination regresses.
  process.standardOutput = stdout
  process.standardError = stderr
  guard case .production(let child) = process.mode else {
    Issue.record("Expected a live process")
    return
  }

  #expect(throws: failure) {
    try process.runAndCaptureOutputUnbounded { handle, index in
      if index == (failure == .stdout ? 0 : 1) { throw failure }
      return try handle.readToEnd()
    }
  }

  #expect(!child.isRunning)
  #expect(child.terminationReason == .uncaughtSignal)
  #expect(child.terminationStatus == SIGKILL)
  #expect(throws: (any Error).self) { try stdout.fileHandleForReading.readToEnd() }
  #expect(throws: (any Error).self) { try stderr.fileHandleForReading.readToEnd() }
}

#if DEBUG
private final class Events: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [String] = []
  func record(_ event: String) { lock.lock(); defer { lock.unlock() }; storage.append(event) }
  var values: [String] { lock.lock(); defer { lock.unlock() }; return storage }
}

@Test(arguments: [CaptureFailure.launch, .stdout, .stderr])
private func unboundedCapturePreservesFailureAndWaitsOnlyAfterLaunch(failure: CaptureFailure) {
  let events = Events()
  let mock = ProcessSystem.Process.Mock(run: {
    events.record("launch")
    if failure == .launch { throw failure }
  }, waitUntilExit: { events.record("wait") }, readStandardOutput: {
    events.record("stdout")
    if failure == .stdout { throw failure }
    return nil
  }, readStandardError: {
    events.record("stderr")
    if failure == .stderr { throw failure }
    return nil
  })
  ProcessSystem.Process.Testing.$mock.withValue(mock) {
    let process = ProcessSystem.Process(.testing, launchStyle: .headless("test"))
    #expect(throws: failure) { try process.runAndCaptureOutputUnbounded() }
  }
  switch failure {
  case .launch: #expect(events.values == ["launch"])
  case .stdout: #expect(events.values == ["launch", "stdout", "wait"])
  case .stderr: #expect(events.values == ["launch", "stdout", "stderr", "wait"])
  }
}
#endif

import Foundation
import Testing
import CowboyCore

@Test func unboundedCaptureDrainsBothStreamsAndReportsStatus() throws {
  let process = Core.Process(.production, launchStyle: .headless("test"))
  process.executableURL = URL(filePath: "/bin/sh")
  process.arguments = ["-c", "head -c 1048576 /dev/zero & head -c 1048576 /dev/zero >&2 & wait; exit 7"]
  process.standardOutput = Core.Pipe(.production)
  process.standardError = Core.Pipe(.production)
  let output = try process.runAndCaptureOutputUnbounded()
  #expect(output.stdout?.count == 1048576)
  #expect(output.stderr?.count == 1048576)
  #expect(process.terminationStatus == 7)
}

private enum CaptureFailure: Error, Equatable { case launch, stdout, stderr }

private final class Events: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [String] = []
  func record(_ event: String) { lock.lock(); defer { lock.unlock() }; storage.append(event) }
  var values: [String] { lock.lock(); defer { lock.unlock() }; return storage }
}

@Test(arguments: [CaptureFailure.launch, .stdout, .stderr])
private func unboundedCapturePreservesFailureAndWaitsOnlyAfterLaunch(failure: CaptureFailure) {
  let events = Events()
  let mock = Core.Process.Mock(run: {
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
  Core.Process.Testing.$mock.withValue(mock) {
    let process = Core.Process(.testing, launchStyle: .headless("test"))
    #expect(throws: failure) { try process.runAndCaptureOutputUnbounded() }
  }
  switch failure {
  case .launch: #expect(events.values == ["launch"])
  case .stdout: #expect(events.values == ["launch", "stdout", "wait"])
  case .stderr: #expect(events.values == ["launch", "stdout", "stderr", "wait"])
  }
}

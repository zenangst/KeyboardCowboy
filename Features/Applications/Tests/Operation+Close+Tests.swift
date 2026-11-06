@testable import ApplicationsFeature
@testable import CowboyCore
import Testing
import Foundation

private final class TerminationRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var applications: [Core.RunningApplication] = []

  func terminate(_ application: Core.RunningApplication) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    applications.append(application)
    return true
  }

  func recordedApplications() -> [Core.RunningApplication] {
    lock.lock()
    defer { lock.unlock() }
    return applications
  }
}

let bundleIdentifier = BundleIdentifier("close.me.please")

@Test func testCloseRunningApplication() async throws {
  try await Core.RunningApplication.Testing.$mock.withValue(.init(
    bundleIdentifier: bundleIdentifier,
    runningApplications: [
      Core.RunningApplication(.testing(nil)),
    ],
    terminate: true,
  ),
  ) {
    let close = Operation.Close(.testing)
    try await #expect(close(bundleIdentifier) == true)
  }
}

@Test func testCloseRunningNonApplication() async throws {
  try await Core.RunningApplication.Testing.$mock.withValue(.init(
    bundleIdentifier: bundleIdentifier,
    runningApplications: [],
    terminate: true,
  ),
  ) {
    let close = Operation.Close(.testing)
    try await #expect(close(bundleIdentifier) == false)
  }
}

@Test func testCloseReportsTerminationFailure() async {
  await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplications: [Core.RunningApplication(.testing(bundleIdentifier))],
    terminate: false
  )) {
    await #expect(throws: Application.Executor.ExecutionError.failedToTerminate(bundleIdentifier)) {
      try await Operation.Close(.testing)(bundleIdentifier)
    }
  }
}

@Test func testCloseTerminatesOnlyFirstMatchingInstance() async throws {
  let first = Core.RunningApplication(.testing(bundleIdentifier))
  let second = Core.RunningApplication(.testing(bundleIdentifier))
  let other = Core.RunningApplication(.testing(.init("other.app")))
  let recorder = TerminationRecorder()
  try await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplications: [other, first, second],
    onTerminate: recorder.terminate
  )) {
    let result = try await Operation.Close(.testing)(bundleIdentifier)
    #expect(result)
  }
  let calls = recorder.recordedApplications()
  #expect(calls.count == 1)
  #expect(calls.first === first)
}

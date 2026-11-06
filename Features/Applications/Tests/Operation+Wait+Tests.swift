@testable import ApplicationsFeature
@testable import CowboyCore
import os
import Testing

private final class WaitScript: Sendable {
  private let responses: OSAllocatedUnfairLock<[Bool]>

  init(_ responses: [Bool]) { self.responses = .init(initialState: responses) }

  func isFinishedLaunching() -> Bool {
    responses.withLock { $0.isEmpty ? false : $0.removeFirst() }
  }
}

private actor SleepRecorder {
  private var sleeps: [Duration] = []

  func recordSleep(_ duration: Duration) {
    sleeps.append(duration)
  }

  func recordedSleeps() -> [Duration] {
    sleeps
  }
}

@Test func testOperationWaitSuccess() async throws {
  let identifier = BundleIdentifier("current.app")
  let script = WaitScript([true])
  let recorder = SleepRecorder()
  let wait = Operation.Wait(.testing, sleep: { await recorder.recordSleep($0) })
  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init(
    isFinishedLaunching: script.isFinishedLaunching,
    runningApplications: [.init(.testing(identifier))]
  )) {
    try await wait(for: identifier)
  }
  #expect(result == .success)
  #expect(await recorder.recordedSleeps() == [.milliseconds(50)])
}

@Test func testOperationWaitTimeOut() async throws {
  let identifier = BundleIdentifier("current.app")
  let script = WaitScript([false, false, false])
  let recorder = SleepRecorder()
  let wait = Operation.Wait(.testing, retries: 3, pollingInterval: .milliseconds(10),
                            sleep: { await recorder.recordSleep($0) })
  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init(
    isFinishedLaunching: script.isFinishedLaunching,
    runningApplications: [.init(.testing(identifier))]
  )) {
    try await wait(for: identifier)
  }
  #expect(result == .timedOut)
  #expect(await recorder.recordedSleeps() == [.milliseconds(10), .milliseconds(10), .milliseconds(10)])
}

@Test func testOperationWaitSkipAppleMusic() async throws {
  let recorder = SleepRecorder()
  let wait = Operation.Wait(.testing, sleep: { await recorder.recordSleep($0) })
  #expect(try await wait(for: BundleIdentifier("com.apple.Music")) == .skipped)
  #expect(await recorder.recordedSleeps().isEmpty)
}

@Test func testWaitOperationForStartingApplication() async throws {
  let identifier = BundleIdentifier("com.starting.app")
  let script = WaitScript([false, false, true])
  let recorder = SleepRecorder()
  let wait = Operation.Wait(.testing, pollingInterval: .milliseconds(10),
                            sleep: { await recorder.recordSleep($0) })
  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init(
    isFinishedLaunching: script.isFinishedLaunching,
    runningApplications: [.init(.testing(identifier))]
  )) {
    try await wait(for: identifier)
  }
  #expect(result == .success)
  #expect(await recorder.recordedSleeps() == [.milliseconds(10), .milliseconds(10), .milliseconds(50)])
}

@Test func testWaitPropagatesSleepCancellation() async {
  let identifier = BundleIdentifier("current.app")
  let wait = Operation.Wait(.testing, sleep: { _ in throw CancellationError() })
  await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplications: [.init(.testing(identifier))]
  )) {
    await #expect(throws: CancellationError.self) { try await wait(for: identifier) }
  }
}

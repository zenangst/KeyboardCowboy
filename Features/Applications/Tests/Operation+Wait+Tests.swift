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
  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplicationsLookup: { _ in Issue.record("Skipped wait must not look up an application"); return [] }
  )) {
    try await wait(for: BundleIdentifier("com.apple.Music"))
  }
  #expect(result == .skipped)
  #expect(await recorder.recordedSleeps().isEmpty)
}

@Test func testWaitSleepFailureStopsFurtherPolling() async {
  let identifier = BundleIdentifier("starting.app")
  let (events, continuation) = AsyncStream<String>.makeStream()
  let wait = Operation.Wait(.testing, retries: 3, sleep: { _ in
    continuation.yield("sleep")
    throw CancellationError()
  })
  await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplicationsLookup: { requested in
      continuation.yield(requested == identifier ? "lookup target" : "lookup unexpected")
      return []
    }
  )) {
    await #expect(throws: CancellationError.self) { try await wait(for: identifier) }
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["lookup target", "sleep"])
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

@Test func testWaitForMissingApplicationSleepsAndTimesOut() async throws {
  let identifier = BundleIdentifier("missing.app")
  let recorder = SleepRecorder()
  let wait = Operation.Wait(.testing, retries: 3, pollingInterval: .milliseconds(10),
                            sleep: { await recorder.recordSleep($0) })
  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init()) {
    try await wait(for: identifier)
  }
  #expect(result == .timedOut)
  #expect(await recorder.recordedSleeps() == [.milliseconds(10), .milliseconds(10), .milliseconds(10)])
}

@Test func testWaitFindsApplicationAfterMissingLookup() async throws {
  let identifier = BundleIdentifier("starting.app")
  let application = Core.RunningApplication(.testing(identifier))
  let lookups = OSAllocatedUnfairLock(initialState: 0)
  let (events, continuation) = AsyncStream<String>.makeStream()
  let wait = Operation.Wait(.testing, retries: 3, pollingInterval: .milliseconds(10),
                            sleep: { continuation.yield("sleep \($0)") })
  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init(
    isFinishedLaunching: { continuation.yield("finished"); return true },
    runningApplicationsLookup: { requested in
      continuation.yield(requested == identifier ? "lookup target" : "lookup unexpected")
      return lookups.withLock { count in
        count += 1
        return count == 1 ? [] : [application]
      }
    }
  )) {
    try await wait(for: identifier)
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(result == .success)
  #expect(recorded == ["lookup target", "sleep \(Duration.milliseconds(10))", "lookup target", "finished", "sleep \(Duration.milliseconds(50))"])
}

@Test func testCancelledWaitDoesNotLookUpApplication() async {
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      withUnsafeCurrentTask { $0?.cancel() }
      return await Core.RunningApplication.Testing.$mock.withValue(.init(
        runningApplicationsLookup: { _ in
          Issue.record("A cancelled wait must not look up an application")
          return []
        }
      )) {
        do {
          _ = try await Operation.Wait(.testing)(for: .init("missing.app"))
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

@Test func testCancelledWaitStillThrowsForSkippedAndZeroRetryCases() async {
  for (identifier, retries) in [("com.apple.Music", 20), ("missing.app", 0)] {
    let cancelled = await Task {
      withUnsafeCurrentTask { $0?.cancel() }
      do {
        _ = try await Operation.Wait(.testing, retries: retries)(for: .init(identifier))
        return false
      } catch is CancellationError {
        return true
      } catch {
        return false
      }
    }.value
    #expect(cancelled)
  }
}

@Test func testWaitChecksCancellationAfterInjectedSleepReturns() async {
  for finished in [false, true] {
    let identifier = BundleIdentifier("current.app")
    let recorder = SleepRecorder()
    let cancelled = await Task {
      let wait = Operation.Wait(.testing, retries: 1, sleep: { duration in
        await recorder.recordSleep(duration)
        withUnsafeCurrentTask { $0?.cancel() }
      })
      return await Core.RunningApplication.Testing.$mock.withValue(.init(
        isFinishedLaunching: { finished },
        runningApplications: [.init(.testing(identifier))]
      )) {
        do {
          _ = try await wait(for: identifier)
          return false
        } catch is CancellationError {
          return true
        } catch {
          return false
        }
      }
    }.value
    #expect(cancelled)
    #expect(await recorder.recordedSleeps() == [finished ? .milliseconds(50) : .milliseconds(100)])
  }
}

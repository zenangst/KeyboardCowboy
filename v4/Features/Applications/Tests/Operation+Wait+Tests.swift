@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

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
  let recorder = SleepRecorder()
  let wait = Operation.Wait(.testing, sleep: { await recorder.recordSleep($0) })
  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init(
    isFinishedLaunching: { true },
    runningApplications: [.init(.testing(identifier))]
  )) {
    try await wait(for: identifier)
  }
  #expect(result == .success)
  #expect(await recorder.recordedSleeps() == [.milliseconds(50)])
}

@Test func testOperationWaitTimeOut() async throws {
  let identifier = BundleIdentifier("current.app")
  let recorder = SleepRecorder()
  let wait = Operation.Wait(.testing, retries: 3, pollingInterval: .milliseconds(10),
                            sleep: { await recorder.recordSleep($0) })
  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init(
    isFinishedLaunching: { false },
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

@Test(arguments: [-1, 0]) func testNonPositiveRetriesDoNotPoll(retries: Int) async throws {
  let wait = Operation.Wait(.testing, retries: retries, sleep: { _ in
    Issue.record("Non-positive retries must not sleep")
  })
  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplicationsLookup: { _ in
      Issue.record("Non-positive retries must not look up an application")
      return []
    }
  )) {
    try await wait(for: BundleIdentifier("missing.app"))
  }
  #expect(result == .timedOut)
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
  let (unfinishedReads, responses) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingOldest(2))
  let recorder = SleepRecorder()
  let wait = Operation.Wait(.testing, pollingInterval: .milliseconds(10),
                            sleep: { await recorder.recordSleep($0) })
  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init(
    isFinishedLaunching: {
      switch responses.yield(()) {
      case .enqueued: false
      case .dropped: true
      case .terminated: false
      @unknown default: false
      }
    },
    runningApplications: [.init(.testing(identifier))]
  )) {
    try await wait(for: identifier)
  }
  #expect(result == .success)
  #expect(await recorder.recordedSleeps() == [.milliseconds(10), .milliseconds(10), .milliseconds(50)])
  responses.finish()
  var readCount = 0
  for await _ in unfinishedReads { readCount += 1 }
  #expect(readCount == 2)
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
  let (missingLookups, responses) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingOldest(1))
  let (events, continuation) = AsyncStream<String>.makeStream()
  let wait = Operation.Wait(.testing, retries: 3, pollingInterval: .milliseconds(10),
                            sleep: { continuation.yield("sleep \($0)") })
  let result = try await Core.RunningApplication.Testing.$mock.withValue(.init(
    isFinishedLaunching: { continuation.yield("finished"); return true },
    runningApplicationsLookup: { requested in
      continuation.yield(requested == identifier ? "lookup target" : "lookup unexpected")
      switch responses.yield(()) {
      case .enqueued: return []
      case .dropped: return [application]
      case .terminated: return []
      @unknown default: return []
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
  responses.finish()
  var missingCount = 0
  for await _ in missingLookups { missingCount += 1 }
  #expect(missingCount == 1)
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

@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

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
  let (events, continuation) = AsyncStream<String>.makeStream()
  try await Core.RunningApplication.Testing.$mock.withValue(.init(
    runningApplicationsLookup: { identifier in
      continuation.yield(identifier == bundleIdentifier ? "lookup target" : "lookup unexpected")
      return [first, second]
    },
    onTerminate: { application in
      continuation.yield(application === first ? "terminate first" : "terminate unexpected")
      return true
    }
  )) {
    let result = try await Operation.Close(.testing)(bundleIdentifier)
    #expect(result)
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["lookup target", "terminate first"])
}

@Test func testCloseCancellationDuringLookupPreventsTermination() async {
  let target = Core.RunningApplication(.testing(bundleIdentifier))
  let (events, continuation) = AsyncStream<String>.makeStream()
  let cancelled = await Task {
    await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { _ in
        continuation.yield("lookup")
        withUnsafeCurrentTask { $0?.cancel() }
        return [target]
      },
      onTerminate: { _ in continuation.yield("terminate"); return true }
    )) {
      do {
        _ = try await Operation.Close(.testing)(bundleIdentifier)
        return false
      } catch is CancellationError {
        return true
      } catch {
        return false
      }
    }
  }.value
  #expect(cancelled)
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["lookup"])
}

#if DEBUG
@testable import ApplicationsFeature
@testable import ApplicationSystem
import Testing

let bundleIdentifier = ApplicationSystem.BundleIdentifier("close.me.please")

@Test func testCloseRunningApplication() async throws {
  try await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
    bundleIdentifier: bundleIdentifier,
    runningApplications: [
      ApplicationSystem.RunningApplication(.testing(nil)),
    ],
    terminate: true,
  ),
  ) {
    let close = Operation.Close(.testing)
    try await #expect(close(bundleIdentifier) == true)
  }
}

@Test func testCloseRunningNonApplication() async throws {
  try await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
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
  await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
    runningApplications: [ApplicationSystem.RunningApplication(.testing(bundleIdentifier))],
    terminate: false,
  )) {
    await #expect(throws: Application.Executor.ExecutionError.failedToTerminate(bundleIdentifier)) {
      try await Operation.Close(.testing)(bundleIdentifier)
    }
  }
}

@Test func testCloseTerminatesOnlyFirstMatchingInstance() async throws {
  let first = ApplicationSystem.RunningApplication(.testing(bundleIdentifier))
  let second = ApplicationSystem.RunningApplication(.testing(bundleIdentifier))
  let (events, continuation) = AsyncStream<String>.makeStream()
  try await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
    runningApplicationsLookup: { identifier in
      continuation.yield(identifier == bundleIdentifier ? "lookup target" : "lookup unexpected")
      return [first, second]
    },
    onTerminate: { application in
      continuation.yield(application === first ? "terminate first" : "terminate unexpected")
      return true
    },
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
  let target = ApplicationSystem.RunningApplication(.testing(bundleIdentifier))
  let (events, continuation) = AsyncStream<String>.makeStream()
  let cancelled = await Task {
    await ApplicationSystem.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { _ in
        continuation.yield("lookup")
        withUnsafeCurrentTask { $0?.cancel() }
        return [target]
      },
      onTerminate: { _ in continuation.yield("terminate"); return true },
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
#endif

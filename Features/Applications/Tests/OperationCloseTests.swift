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

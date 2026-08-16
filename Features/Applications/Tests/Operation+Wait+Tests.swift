@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

@Test func testOperationWaitSuccess() async throws {
  let currentBundleIdentifier = BundleIdentifier("current.app")
  let currentRunningApplication = Core.RunningApplication(.testing(currentBundleIdentifier))
  let wait = Operation.Wait(.testing)

  try await Core.RunningApplication.Testing.$mock.withValue(
    .init(isFinishedLaunching: true,
          runningApplications: [currentRunningApplication]),
    operation: {
      do {
        #expect(try await wait(for: currentBundleIdentifier) == .success)
      } catch {
        throw error
      }
    })
}

@Test func testOperationWaitTimeOut() async throws {
  let currentBundleIdentifier = BundleIdentifier("current.app")
  let currentRunningApplication = Core.RunningApplication(.testing(currentBundleIdentifier))
  let wait = Operation.Wait(.testing, pollingInterval: .milliseconds(1))

  try await Core.RunningApplication.Testing.$mock.withValue(
    .init(isFinishedLaunching: false,
          runningApplications: [currentRunningApplication]),
    operation: {
      do {
        #expect(try await wait(for: currentBundleIdentifier) == .timedOut)
      } catch {
        throw error
      }
    })
}

@Test func testOperationWaitSkipAppleMusic() async throws {
  let appleMusic = BundleIdentifier("com.apple.Music")
  let wait = Operation.Wait(.testing)

  #expect(try await wait(for: appleMusic) == .skipped)
}

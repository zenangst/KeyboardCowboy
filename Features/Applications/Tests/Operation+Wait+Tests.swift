@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

@Test func testOperationWaitSuccess() async throws {
  let currentBundleIdentifier = BundleIdentifier("current.app")
  let currentRunningApplication = Core.RunningApplication(.testing(currentBundleIdentifier))
  let wait = Operation.Wait(.testing)

  try await Core.RunningApplication.Testing.$mock.withValue(
    .init(isFinishedLaunching: { true },
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
    .init(isFinishedLaunching: { false },
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

@Test func testWaitOperationForStartingApplication() async throws {
  let wait = Operation.Wait(.testing)
  let bundleIdentifier = BundleIdentifier("com.starting.app")
  let launcher = IsFinishedLaunching { false }

  try await Core.RunningApplication.Testing.$mock.withValue(.init(
    isFinishedLaunching: {
      launcher.closure()
    },
    runningApplications: [
      .init(.testing(bundleIdentifier)),
    ]), operation: {
    Task.detached {
      try? await Task.sleep(for: .milliseconds(100))
      launcher.update { true }
    }

    let result = try await wait(for: bundleIdentifier)
    #expect(result == .success)
  })
}

private final class IsFinishedLaunching: @unchecked Sendable {
  private(set) var closure: () -> Bool

  init(_ closure: @escaping () -> Bool) {
    self.closure = closure
  }

  func update(_ closure: @escaping () -> Bool) {
    self.closure = closure
  }
}

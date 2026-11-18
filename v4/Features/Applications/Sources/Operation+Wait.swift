import ApplicationSystem
import Foundation
import RuntimeEnvironment

extension Operation {
  final class Wait: Sendable {
    enum Result: Hashable {
      case success
      case timedOut
      case skipped
    }

    let env: RuntimeEnvironment.Mode
    let retries: Int
    let pollingInterval: Duration
    let skippableBundleIdentifiers: Set<ApplicationSystem.BundleIdentifier> = [ApplicationSystem.BundleIdentifier("com.apple.Music")]
    let workspace: Application.Workspace
    let finalSleepDuration: Duration
    private let sleep: @Sendable (Duration) async throws -> Void

    init(_ env: RuntimeEnvironment.Mode,
         retries: Int = 20,
         finalSleepDuration: Duration = .milliseconds(50),
         pollingInterval: Duration = .milliseconds(100),
         sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
    ) {
      self.env = env
      self.pollingInterval = pollingInterval
      self.retries = retries
      self.finalSleepDuration = finalSleepDuration
      self.workspace = Application.Workspace(env)
      self.sleep = sleep
    }

    @discardableResult
    func callAsFunction(for bundleIdentifier: ApplicationSystem.BundleIdentifier) async throws -> Result {
      try Task.checkCancellation()
      guard !skippableBundleIdentifiers.contains(bundleIdentifier) else {
        return .skipped
      }

      var retries = self.retries
      while retries > 0 {
        try Task.checkCancellation()
        if let application = ApplicationSystem.RunningApplication.application(with: bundleIdentifier, env: env),
           application.isFinishedLaunching {
          try Task.checkCancellation()
          try await sleep(finalSleepDuration)
          try Task.checkCancellation()
          return .success
        }

        try Task.checkCancellation()
        try await sleep(pollingInterval)
        try Task.checkCancellation()
        retries -= 1
      }

      return .timedOut
    }
  }
}

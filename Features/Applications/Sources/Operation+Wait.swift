import CowboyCore
import Foundation

extension Operation {
  final class Wait {
    enum Result: Hashable {
      case success
      case timedOut
      case skipped
    }

    let env: Core.Environment
    let retries: Int
    let pollingInterval: Duration
    let skippableBundleIdentifiers: Set<BundleIdentifier> = [BundleIdentifier("com.apple.Music")]
    let workspace: Core.Workspace
    let finalSleepDuration: Duration

    init(_ env: Core.Environment,
         retries: Int = 20,
         finalSleepDuration: Duration = .milliseconds(50),
         pollingInterval: Duration = .milliseconds(100),
    ) {
      self.env = env
      self.pollingInterval = pollingInterval
      self.retries = retries
      self.finalSleepDuration = finalSleepDuration
      self.workspace = Core.Workspace(env)
    }

    @discardableResult
    func callAsFunction(for bundleIdentifier: BundleIdentifier) async throws -> Result {
      guard !skippableBundleIdentifiers.contains(bundleIdentifier) else {
        return .skipped
      }

      var waiting = true
      var retries = self.retries
      var result: Result = .timedOut

      while waiting {
        if retries == 0 {
          waiting = false
          break
        }

        guard let application = Core.RunningApplication.application(with: bundleIdentifier, env: env) else {
          retries -= 1
          continue
        }

        if application.isFinishedLaunching {
          try await Task.sleep(for: finalSleepDuration)
          waiting = false
          result = .success
          break
        }

        try await Task.sleep(for: pollingInterval)
        retries -= 1
      }

      return result
    }
  }
}

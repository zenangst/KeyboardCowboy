import Cocoa
import CowboyCore

extension Operation {
  final class Restart {
    typealias Environment = Core.Environment
    typealias RunningApplication = Core.RunningApplication

    enum Result: Hashable {
      case success
      case timedOut
      case skipped
    }

    private let env: Environment
    private let retries: Int
    private let pollingInterval: Duration
    private let workspace: Core.Workspace

    init(_ env: Environment, retries: Int, pollingInterval: Duration) {
      self.env = env
      self.retries = retries
      self.pollingInterval = pollingInterval
      self.workspace = Core.Workspace(env)
    }

    func callAsFunction(_ bundleIdentifier: BundleIdentifier) async throws -> Result {
      guard let application = RunningApplication.application(with: bundleIdentifier, env: env) else {
        return .skipped
      }

      let applicationToTerminate = { [env] in RunningApplication.application(with: bundleIdentifier, env: env) == nil }
      let applicationToLaunch = { [env] in RunningApplication.application(with: bundleIdentifier, env: env) != nil }

      application.terminate()
      switch try await poll(for: applicationToTerminate) {
      case .success:
        guard let bundleURL = application.bundleURL else {
          return .skipped
        }

        let configuration = NSWorkspace.OpenConfiguration()
        let applicationURL = URL(fileURLWithPath: bundleURL.path())

        try await workspace.openApplication(
          at: applicationURL,
          configuration: configuration,
        )

        return try await poll(for: applicationToLaunch)

      case .timedOut:
        return .timedOut

      case .skipped:
        return .skipped
      }
    }

    private func poll(for condition: () -> Bool) async throws -> Result {
      var result: Result = .skipped
      var waiting = true
      var retries = self.retries

      while waiting {
        if retries <= 0 {
          waiting = false
          result = .timedOut
        } else if condition() {
          waiting = false
          result = .success
        } else {
          retries -= 1
          try await Task.sleep(for: pollingInterval)
          result = .timedOut
        }
      }

      return result
    }
  }
}

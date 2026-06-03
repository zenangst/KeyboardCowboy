import CowboyCore

extension Operation {
  final class Wait {
    let env: Core.Environment
    let retries: Int
    let skippableBundleIdentifiers: Set<BundleIdentifier> = [BundleIdentifier("com.apple.Music")]
    let workspace: Core.Workspace

    init(_ env: Core.Environment, retries: Int = 20) {
      self.env = env
      self.retries = retries
      self.workspace = Core.Workspace(env)
    }

    func callAsFunction(_ bundleIdentifier: BundleIdentifier) async throws {
      guard !skippableBundleIdentifiers.contains(bundleIdentifier) else { return }

      var waiting = true
      var retries = self.retries

      while waiting {
        guard let application = Core.RunningApplication.runningApplication(with: bundleIdentifier, env: env) else {
          retries -= 1
          continue
        }

        if application.isFinishedLaunching {
          try await Task.sleep(for: .milliseconds(50))
          waiting = false
          break
        }

        try? await Task.sleep(for: .milliseconds(100))
        retries -= 1

        if retries == 0 {
          waiting = false
        }
      }
    }
  }
}

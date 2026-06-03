import CowboyCore

extension Operation {
  final class Close {
    private let env: Core.Environment

    init(_ env: Core.Environment) {
      self.env = env
    }

    @discardableResult
    func callAsFunction(_ bundleIdentifier: Core.BundleIdentifier) async throws -> Bool {
      guard let application = Core.RunningApplication.runningApplication(with: bundleIdentifier, env: env) else {
        return false
      }

      return application.terminate()
    }
  }
}

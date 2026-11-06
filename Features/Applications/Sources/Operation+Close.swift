import CowboyCore

extension Operation {
  final class Close: Sendable {
    private let env: Core.Environment

    init(_ env: Core.Environment) {
      self.env = env
    }

    @discardableResult
    func callAsFunction(_ bundleIdentifier: Core.BundleIdentifier) async throws -> Bool {
      try Task.checkCancellation()
      guard let application = Core.RunningApplication.application(with: bundleIdentifier, env: env) else {
        try Task.checkCancellation()
        return false
      }

      try Task.checkCancellation()
      guard application.terminate() else {
        try Task.checkCancellation()
        throw Application.Executor.ExecutionError.failedToTerminate(bundleIdentifier)
      }
      try Task.checkCancellation()
      return true
    }
  }
}

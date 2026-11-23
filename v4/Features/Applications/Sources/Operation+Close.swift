import ApplicationSystem
import RuntimeEnvironment

extension Operation {
  final class Close: Sendable {
    private let env: RuntimeEnvironment.Mode

    init(_ env: RuntimeEnvironment.Mode) {
      self.env = env
    }

    @discardableResult
    func callAsFunction(_ bundleIdentifier: ApplicationSystem.BundleIdentifier) async throws -> Bool {
      try Task.checkCancellation()
      guard let application = ApplicationSystem.RunningApplication.application(with: bundleIdentifier, env: env) else {
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

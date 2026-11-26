import ApplicationSystem

public extension Application.Executor {
  enum ExecutionError: Error, Equatable, Sendable {
    case failedToTerminate(ApplicationSystem.BundleIdentifier)
    case failedToActivate(ApplicationSystem.BundleIdentifier)
    case applicationNotRunning(ApplicationSystem.BundleIdentifier)
    case missingFrontmostApplication
  }
}

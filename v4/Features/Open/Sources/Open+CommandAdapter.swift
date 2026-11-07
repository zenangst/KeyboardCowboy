import CowboyCore

public extension Open.Executor {
  /// The host resolves interpolation and applies metadata policy before calling.
  func run(_ command: Command.Open, resolvedPath: String, checkCancellation: Bool) async throws {
    let application = command.application.map {
      Open.TargetApplication(
        bundleIdentifier: $0.bundleIdentifier,
        bundleName: $0.bundleName,
        displayName: $0.displayName,
        path: $0.path
      )
    }
    try await run(resolvedPath, application: application, checkCancellation: checkCancellation)
  }
}

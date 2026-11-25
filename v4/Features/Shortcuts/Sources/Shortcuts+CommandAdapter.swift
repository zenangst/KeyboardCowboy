import Commands

public extension Shortcuts.Executor {
  /// The host applies metadata policy and formats the returned output.
  func run(_ command: Command.Shortcut, cancellation: Shortcuts.CancellationPolicy) async throws -> String? {
    try await run(command.shortcutIdentifier, cancellation: cancellation)
  }
}

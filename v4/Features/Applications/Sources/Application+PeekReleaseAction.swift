import Commands

public extension Application.Executor {
  /// A host may restore a previous application instead of hiding on peek release.
  enum PeekReleaseAction: Sendable {
    case hide
    /// Supply an ordinary open command for the application's previous target.
    case open(Command.Application)
    case none

    /// Matches the legacy release policy. The caller supplies its activity-history
    /// result and controls whether a physical release is eligible for execution.
    public static func resolve(stageManagerEnabled: Bool,
                               previous: Command.Application?) -> Self {
      guard stageManagerEnabled else { return .hide }
      guard let previous else { return .none }

      // Legacy creates a fresh ordinary-open command for the previous application.
      return .open(Command.Application(application: previous.application))
    }
  }
}

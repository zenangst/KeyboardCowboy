import Commands
import CowboyCore

public extension Application.Executor.PeekReleaseAction {
  /// Matches the legacy release policy. The caller supplies its activity-history
  /// result and controls whether a physical release is eligible for execution.
  static func resolve(stageManagerEnabled: Bool,
                      previous: Command.Application?) -> Self {
    guard stageManagerEnabled else { return .hide }
    guard let previous else { return .none }
    // Legacy creates a fresh ordinary-open command for the previous application.
    return .open(Command.Application(application: previous.application))
  }
}

import Commands

public extension SystemCommand {
  /// Hides eligible applications only within an explicitly supplied process set.
  @MainActor
  static func hideAllApps(
    workflowApplications: [Command.Application], limitingTo processIdentifiers: Set<Int32>,
  ) async throws {
    try await Operation.HideAllApps.live(limitingTo: processIdentifiers)(workflowApplications)
  }
}

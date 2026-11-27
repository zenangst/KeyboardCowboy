public extension WorkflowRuntime {
  enum Lane: Sendable {
    /// Starting a run does not cancel earlier runs. Each run honors step delays.
    case serial
    /// Replaces earlier runs in this lane and skips step delays. Steps still run in order.
    case concurrent
  }
}

public extension WorkflowRuntime {
  enum FailureDecision: Sendable {
    case proceed, abort
  }
}

public extension WorkflowRuntime {
  enum Origin: Equatable, Sendable {
    case manual
    case applicationTrigger(bundleIdentifier: String, context: String)
  }
}

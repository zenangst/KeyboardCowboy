public extension WorkflowRuntime {
  enum Outcome: Sendable {
    case succeeded(commandID: String, output: String)
    case failed(commandID: String, error: any Error)
  }
}

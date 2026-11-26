public extension WorkflowRuntime {
  struct Request<Payload: Sendable>: Sendable {
    public let workflowID: String
    public let origin: Origin
    public let steps: [Step<Payload>]

    public init(workflowID: String, origin: Origin, steps: [Step<Payload>]) {
      self.workflowID = workflowID
      self.origin = origin
      self.steps = steps
    }
  }
}

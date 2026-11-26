public extension WorkflowRuntime {
  struct Context<Snapshot: Sendable>: Sendable {
    public var snapshot: Snapshot
    public var variables: [String: String]

    public init(snapshot: Snapshot, variables: [String: String] = [:]) {
      self.snapshot = snapshot
      self.variables = variables
    }
  }
}

public extension WorkflowRuntime {
  struct CommandResult<Snapshot: Sendable>: Sendable {
    public let snapshot: Snapshot
    public let output: String
    let variables: [String: String]?

    public init(snapshot: Snapshot, output: String) {
      self.snapshot = snapshot
      self.output = output
      variables = nil
    }

    /// Forward the returned context of a shared child before writing this command's output.
    public init(context: Context<Snapshot>, output: String) {
      snapshot = context.snapshot
      self.output = output
      variables = context.variables
    }
  }
}

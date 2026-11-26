public extension WorkflowRuntime {
  struct CommandResult<Snapshot: Sendable>: Sendable {
    public let snapshot: Snapshot
    public let output: String

    public init(snapshot: Snapshot, output: String) {
      self.snapshot = snapshot
      self.output = output
    }
  }
}

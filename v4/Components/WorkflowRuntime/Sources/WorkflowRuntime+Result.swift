public extension WorkflowRuntime {
  struct Result<Snapshot: Sendable>: Sendable {
    public let context: Context<Snapshot>
    public let outcomes: [Outcome]
  }
}

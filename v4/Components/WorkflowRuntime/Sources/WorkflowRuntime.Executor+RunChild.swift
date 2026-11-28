public extension WorkflowRuntime.Executor {
  /// Awaits a child in the current task and lane. Its outcomes remain separate.
  /// Forward successful context explicitly. A shared child using
  /// `delayAfterSuccessAndAbortOnFailure` throws `SharedChildFailure` on a step error.
  @MainActor
  struct RunChild {
    let execute: @MainActor (
      WorkflowRuntime.Request<Payload>,
      WorkflowRuntime.ChildContext<Snapshot>,
      WorkflowRuntime.ChildPolicy,
    ) async throws -> WorkflowRuntime.Result<Snapshot>

    public func callAsFunction(
      _ request: WorkflowRuntime.Request<Payload>,
      _ context: WorkflowRuntime.ChildContext<Snapshot>,
      policy: WorkflowRuntime.ChildPolicy = .laneDefault,
    ) async throws -> WorkflowRuntime.Result<Snapshot> {
      try await execute(request, context, policy)
    }
  }
}

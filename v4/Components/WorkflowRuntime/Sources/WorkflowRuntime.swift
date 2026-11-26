public enum WorkflowRuntime {
  @MainActor
  public struct Executor<Payload: Sendable, Snapshot: Sendable> {
    public typealias Dispatch = @MainActor (
      Step<Payload>,
      Request<Payload>,
      Context<Snapshot>,
    ) async throws -> CommandResult<Snapshot>

    public typealias FailurePolicy = @MainActor (Step<Payload>, any Error) -> FailureDecision

    private let dispatch: Dispatch
    private let failurePolicy: FailurePolicy
    private let sleep: @MainActor (Duration) async throws -> Void

    public init(
      failurePolicy: @escaping FailurePolicy = { _, _ in .proceed },
      sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
      dispatch: @escaping Dispatch,
    ) {
      self.dispatch = dispatch
      self.failurePolicy = failurePolicy
      self.sleep = sleep
    }

    /// Runs one ordered list; the caller owns its task. Ordinary failures continue
    /// by default. Cancellation always throws and does not roll back dispatched effects.
    public func run(
      _ request: Request<Payload>,
      from initialContext: Context<Snapshot>,
    ) async throws -> Result<Snapshot> {
      try Task.checkCancellation()
      let enabled = Request(workflowID: request.workflowID, origin: request.origin,
                            steps: request.steps.filter(\.metadata.isEnabled))
      var context = initialContext
      var outcomes: [Outcome] = []
      for step in enabled.steps {
        try Task.checkCancellation()
        do {
          let result = try await dispatch(step, enabled, context)
          try Task.checkCancellation()
          context.snapshot = result.snapshot
          if let name = step.metadata.variableName {
            context.variables[name] = result.output
          }
          outcomes.append(.succeeded(commandID: step.metadata.id, output: result.output))
        } catch is CancellationError {
          throw CancellationError()
        } catch {
          try Task.checkCancellation()
          if failurePolicy(step, error) == .abort { throw error }
          outcomes.append(.failed(commandID: step.metadata.id, error: error))
        }
        try Task.checkCancellation()
        // Match serial post-command timing. Ignore nonpositive or unrepresentable delays.
        if let delay = step.metadata.delay, delay > 0, delay < Double(Int64.max) {
          try await sleep(.milliseconds(delay))
          try Task.checkCancellation()
        }
      }
      return Result(context: context, outcomes: outcomes)
    }
  }
}

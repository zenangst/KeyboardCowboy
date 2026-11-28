public extension WorkflowRuntime {
  @MainActor
  struct Executor<Payload: Sendable, Snapshot: Sendable> {
    public typealias Dispatch = @MainActor (
      Step<Payload>,
      Request<Payload>,
      Context<Snapshot>,
    ) async throws -> CommandResult<Snapshot>

    public typealias NestedDispatch = @MainActor (
      Step<Payload>,
      Request<Payload>,
      Context<Snapshot>,
      RunChild,
    ) async throws -> CommandResult<Snapshot>

    /// Classifies ordinary failures in the run's lane, including inline children.
    /// Cancellation does not reach this policy.
    public typealias FailurePolicy = @MainActor (Step<Payload>, any Error, Lane) -> FailureDecision

    private let dispatch: NestedDispatch
    private let failurePolicy: FailurePolicy
    private let sleep: @MainActor (Duration) async throws -> Void

    public init(
      failurePolicy: @escaping FailurePolicy = { _, _, _ in .proceed },
      sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
      dispatch: @escaping Dispatch,
    ) {
      self.init(failurePolicy: failurePolicy, sleep: sleep, dispatchingNested: { step, request, context, _ in
        try await dispatch(step, request, context)
      })
    }

    public init(
      failurePolicy: @escaping FailurePolicy = { _, _, _ in .proceed },
      sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
      dispatchingNested: @escaping NestedDispatch,
    ) {
      self.dispatch = dispatchingNested
      self.failurePolicy = failurePolicy
      self.sleep = sleep
    }

    /// Runs one ordered list; the caller owns its task. The lane only controls delays
    /// here; use `Scheduler` for replacement. Ordinary failures continue by default.
    /// Cancellation always throws and does not roll back dispatched effects.
    public func run(
      _ request: Request<Payload>,
      from initialContext: Context<Snapshot>,
      lane: Lane = .serial,
    ) async throws -> Result<Snapshot> {
      try await run(request, from: initialContext, lane: lane, policy: .laneDefault, ancestors: [])
    }

    private func run(
      _ request: Request<Payload>,
      from initialContext: Context<Snapshot>,
      lane: Lane,
      policy: ChildPolicy,
      ancestors: Set<String>,
      forwardsPartialContext: Bool = false,
    ) async throws -> Result<Snapshot> {
      try Task.checkCancellation()
      guard !ancestors.contains(request.workflowID) else {
        throw ReentryError(workflowID: request.workflowID)
      }
      let path = ancestors.union([request.workflowID])
      let enabled = Request(workflowID: request.workflowID, origin: request.origin,
                            steps: request.steps.filter(\.metadata.isEnabled))
      var context = initialContext
      var outcomes: [Outcome] = []
      for step in enabled.steps {
        try Task.checkCancellation()
        do {
          let result = try await dispatch(step, enabled, context, RunChild { child, childContext, childPolicy in
            try await run(
              child, from: childContext.initial, lane: lane, policy: childPolicy, ancestors: path,
              forwardsPartialContext: childContext.isShared && childPolicy == .delayAfterSuccessAndAbortOnFailure,
            )
          })
          try Task.checkCancellation()
          context.snapshot = result.snapshot
          if let variables = result.variables {
            context.variables = variables
          }
          if let name = step.metadata.variableName {
            context.variables[name] = result.output
          }
          outcomes.append(.succeeded(commandID: step.metadata.id, output: result.output))
        } catch is CancellationError {
          throw CancellationError()
        } catch {
          try Task.checkCancellation()
          let childFailure = error as? SharedChildFailure<Snapshot>
          if let childFailure { context = childFailure.context }
          let cause = childFailure?.cause ?? error
          if policy == .delayAfterSuccessAndAbortOnFailure || failurePolicy(step, cause, lane) == .abort {
            if forwardsPartialContext { throw SharedChildFailure(context: context, cause: cause) }
            throw cause
          }
          outcomes.append(.failed(commandID: step.metadata.id, error: cause))
        }
        try Task.checkCancellation()
        // Ignore nonpositive or unrepresentable delays.
        if lane == .serial || policy == .delayAfterSuccessAndAbortOnFailure,
           let delay = step.metadata.delay, delay > 0, delay < Double(Int64.max) {
          try await sleep(.milliseconds(delay))
          try Task.checkCancellation()
        }
      }
      return Result(context: context, outcomes: outcomes)
    }
  }
}

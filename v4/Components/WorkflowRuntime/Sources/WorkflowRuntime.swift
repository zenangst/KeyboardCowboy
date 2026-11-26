import Commands

public enum WorkflowRuntime {
  public enum Origin: Equatable, Sendable {
    case manual
    case applicationTrigger(bundleIdentifier: String, context: String)
  }

  public struct Step<Payload: Sendable>: Sendable {
    public let metadata: Command.Metadata
    public let payload: Payload

    public init(metadata: Command.Metadata, payload: Payload) {
      self.metadata = metadata
      self.payload = payload
    }
  }

  public struct Request<Payload: Sendable>: Sendable {
    public let workflowID: String
    public let origin: Origin
    public let steps: [Step<Payload>]

    public init(workflowID: String, origin: Origin, steps: [Step<Payload>]) {
      self.workflowID = workflowID
      self.origin = origin
      self.steps = steps
    }
  }

  public struct Context<Snapshot: Sendable>: Sendable {
    public var snapshot: Snapshot
    public var variables: [String: String]

    public init(snapshot: Snapshot, variables: [String: String] = [:]) {
      self.snapshot = snapshot
      self.variables = variables
    }
  }

  public struct CommandResult<Snapshot: Sendable>: Sendable {
    public let snapshot: Snapshot
    public let output: String

    public init(snapshot: Snapshot, output: String) {
      self.snapshot = snapshot
      self.output = output
    }
  }

  public enum Outcome: Sendable {
    case succeeded(commandID: String, output: String)
    case failed(commandID: String, error: any Error)
  }

  public struct Result<Snapshot: Sendable>: Sendable {
    public let context: Context<Snapshot>
    public let outcomes: [Outcome]
  }

  public enum FailureDecision: Sendable {
    case proceed, abort
  }

  @MainActor
  public struct Executor<Payload: Sendable, Snapshot: Sendable> {
    public typealias Dispatch = @MainActor (Step<Payload>, Request<Payload>, Context<Snapshot>) async throws -> CommandResult<Snapshot>
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
    public func run(_ request: Request<Payload>, from initialContext: Context<Snapshot>) async throws -> Result<Snapshot> {
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

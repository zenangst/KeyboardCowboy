import Foundation

public extension WorkflowRuntime {
  @MainActor
  final class Scheduler<Payload: Sendable, Snapshot: Sendable> {
    private let executor: Executor<Payload, Snapshot>
    private var runs: [UUID: (lane: Lane, task: Task<Result<Snapshot>, any Error>)] = [:]

    public init(executor: Executor<Payload, Snapshot>) {
      self.executor = executor
    }

    /// Starts a run and returns its result and cancellation handle. A host can
    /// request cancellation of both lanes before starting, independent of lane.
    /// Replacement is cooperative: it does not wait for an in-flight effect to finish.
    public func start(
      _ request: Request<Payload>,
      from context: Context<Snapshot>,
      lane: Lane = .serial,
      cancelPrevious: Bool = false,
    ) -> Task<Result<Snapshot>, any Error> {
      for run in runs.values where cancelPrevious || (lane == .concurrent && run.lane == .concurrent) {
        run.task.cancel()
      }

      let id = UUID()
      let task = Task(priority: .userInitiated) { [weak self, executor] in
        defer { self?.runs[id] = nil }
        return try await executor.run(request, from: context, lane: lane)
      }
      runs[id] = (lane, task)
      return task
    }

    /// Requests cancellation of all outstanding runs, including overlapping serial runs.
    public func cancelAll() {
      for run in runs.values { run.task.cancel() }
    }
  }
}

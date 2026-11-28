public extension WorkflowRuntime {
  /// Carries completed shared child updates when the opted-in child policy
  /// aborts. If rethrown by the dispatcher, the parent applies the context
  /// before classifying the original error. Cancellation is never wrapped.
  struct SharedChildFailure<Snapshot: Sendable>: Error {
    public let context: Context<Snapshot>
    public let cause: any Error
  }
}

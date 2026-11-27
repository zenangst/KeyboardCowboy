public extension WorkflowRuntime {
  /// The requested child duplicates an ID already on its active workflow path.
  struct ReentryError: Error, Equatable {
    public let workflowID: String
  }
}

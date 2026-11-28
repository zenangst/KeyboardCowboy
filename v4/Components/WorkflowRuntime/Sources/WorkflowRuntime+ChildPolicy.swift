public extension WorkflowRuntime {
  enum ChildPolicy: Sendable {
    /// Use the lane's usual delay and the executor's failure classifier.
    case laneDefault
    /// Delay after each successful step in either lane. Throw the first ordinary
    /// failure to the caller without classifying it or delaying that step.
    case delayAfterSuccessAndAbortOnFailure
  }
}

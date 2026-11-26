public extension SystemCommand {
  enum Completion: Equatable, Sendable {
    /// The system operation returned; this does not confirm every visible effect.
    case invoked
    /// The Applications executor finished its ordinary open request; focus is not verified.
    case applicationOpenCompleted
    case noPreviousApplication
  }
}

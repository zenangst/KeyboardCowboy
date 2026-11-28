public extension WorkflowRuntime {
  enum ChildContext<Snapshot: Sendable>: Sendable {
    /// Use the current context. Forward the child result explicitly on success.
    /// An opted-in abort can carry completed updates back with the error.
    case shared(Context<Snapshot>)
    /// Use a freshly captured snapshot and no parent variables. Keep the result local to the child.
    case isolated(snapshot: Snapshot)

    var initial: Context<Snapshot> {
      switch self {
      case .shared(let context): context
      case .isolated(let snapshot): .init(snapshot: snapshot)
      }
    }

    var isShared: Bool {
      if case .shared = self { return true }
      return false
    }
  }
}

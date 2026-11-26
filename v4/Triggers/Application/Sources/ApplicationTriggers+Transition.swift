public extension ApplicationTriggers {
  enum Transition: Sendable {
    /// Lists can contain multiple processes for a bundle. Seed the initial list without matching it.
    case runningApplications(previous: [String], current: [String])
    /// Pass nil when no application is frontmost. Repeated bundle IDs are not transitions.
    case frontmostApplication(previous: String?, current: String?)
  }

  struct Match: Equatable, Sendable {
    public let workflowID: String
    public let bundleIdentifier: String
    public let context: Context
  }
}

public extension ApplicationTriggers {
  enum Context: String, Codable, CaseIterable, Sendable {
    case closed, launched, frontMost, resignFrontMost
  }

  struct Rule: Sendable {
    public let workflowID: String
    public let bundleIdentifier: String
    public let contexts: Set<Context>
    public let requiredModeIDs: Set<String>
    public let isGroupEnabled: Bool
    public let isWorkflowEnabled: Bool

    public init(
      workflowID: String,
      bundleIdentifier: String,
      contexts: Set<Context>,
      requiredModeIDs: Set<String> = [],
      isGroupEnabled: Bool = true,
      isWorkflowEnabled: Bool = true,
    ) {
      self.workflowID = workflowID
      self.bundleIdentifier = bundleIdentifier
      self.contexts = contexts
      self.requiredModeIDs = requiredModeIDs
      self.isGroupEnabled = isGroupEnabled
      self.isWorkflowEnabled = isWorkflowEnabled
    }
  }
}

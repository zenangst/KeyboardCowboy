public extension KeyboardTriggers {
  struct Rule: Sendable {
    public let workflowID: String
    public let signature: Signature
    public let continuation: [Signature]
    public let endsWithAnyKey: Bool
    public let passthrough: Bool
    public let allowRepeat: Bool
    public let holdDuration: Duration?
    public let allowedBundleIdentifiers: Set<String>
    public let disallowedBundleIdentifiers: Set<String>
    public let modeIDs: Set<String>
    public let isGroupEnabled: Bool
    public let isWorkflowEnabled: Bool

    /// An empty allowed set means global. A nonempty mode set matches any
    /// listed active mode, in the caller's priority order.
    public init(
      workflowID: String,
      signature: Signature,
      allowedBundleIdentifiers: Set<String> = [],
      disallowedBundleIdentifiers: Set<String> = [],
      modeIDs: Set<String> = [],
      isGroupEnabled: Bool = true,
      isWorkflowEnabled: Bool = true,
      continuation: [Signature] = [],
      endsWithAnyKey: Bool = false,
      passthrough: Bool = false,
      allowRepeat: Bool = true,
      holdDuration: Duration? = nil,
    ) {
      self.workflowID = workflowID
      self.signature = signature
      self.continuation = continuation
      self.endsWithAnyKey = endsWithAnyKey
      self.passthrough = passthrough
      self.allowRepeat = allowRepeat
      self.holdDuration = holdDuration
      self.allowedBundleIdentifiers = allowedBundleIdentifiers
      self.disallowedBundleIdentifiers = disallowedBundleIdentifiers
      self.modeIDs = modeIDs
      self.isGroupEnabled = isGroupEnabled
      self.isWorkflowEnabled = isWorkflowEnabled
    }
  }
}

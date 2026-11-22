public extension AccessibilitySystem {
  struct Configuration: Sendable {
    /// Per-message timeout, not an overall transaction deadline.
    public var messagingTimeout: Duration

    public init(messagingTimeout: Duration = .milliseconds(250)) {
      self.messagingTimeout = messagingTimeout
    }
  }
}

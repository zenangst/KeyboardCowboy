public extension KeyboardTriggers {
  struct SequenceSession: Sendable {
    private let matcher: Matcher
    private let timeout: Duration
    private var prefix: [Signature] = []
    private var lastInput: Duration?
    private var app: String?
    private var modes: [String] = []

    /// The timeout is measured between consecutive keys using caller-supplied monotonic time.
    public init(matcher: Matcher, timeout: Duration) {
      self.matcher = matcher
      self.timeout = timeout
    }

    /// Feed eligible key-down events only. A mismatch retries the current key as
    /// a fresh start. At a shared prefix, scope/mode and rule order choose
    /// between completing a shortcut and waiting for another key.
    public mutating func receive(
      _ signature: Signature, at time: Duration, frontmostBundleIdentifier: String?, enabledModeIDs: [String] = [],
    ) -> SequenceMatch {
      receiveDecision(signature, at: time, frontmostBundleIdentifier: frontmostBundleIdentifier,
                      enabledModeIDs: enabledModeIDs).match
    }

    /// Reports how the host should handle the current key-down alongside the match.
    /// It does not post events, run workflows, or change previously handled keys.
    public mutating func receiveDecision(
      _ signature: Signature, at time: Duration, frontmostBundleIdentifier: String?, enabledModeIDs: [String] = [],
    ) -> Decision {
      if let lastInput,
         time < lastInput || time - lastInput >= timeout || app != frontmostBundleIdentifier || modes != enabledModeIDs {
        reset()
      }

      prefix.append(signature)
      var decision = matcher.matchSequence(prefix, frontmostBundleIdentifier: frontmostBundleIdentifier,
                                           enabledModeIDs: enabledModeIDs)
      if decision.match == .noMatch, prefix.count > 1 {
        prefix = [signature]
        decision = matcher.matchSequence(prefix, frontmostBundleIdentifier: frontmostBundleIdentifier,
                                         enabledModeIDs: enabledModeIDs)
      }

      if decision.match == .partial {
        lastInput = time
        app = frontmostBundleIdentifier
        modes = enabledModeIDs
      } else {
        reset()
      }
      return decision
    }

    /// Clear pending input on disruption, capture handoff, or layout changes.
    public mutating func reset() {
      prefix.removeAll(keepingCapacity: true)
      lastInput = nil
      app = nil
      modes = []
    }
  }
}

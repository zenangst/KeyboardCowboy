public extension KeyboardTriggers {
  struct SequenceSession: Sendable {
    private let matcher: Matcher
    private let timeout: Duration
    private var prefix: [Signature] = []
    private var lastInput: Duration?
    private var app: String?
    private var modes: [String] = []
    private var suppressedKeyCodes: Set<UInt16> = []

    /// The timeout is measured between consecutive keys using caller-supplied monotonic time.
    public init(matcher: Matcher, timeout: Duration) {
      self.matcher = matcher
      self.timeout = timeout
    }

    /// Feed eligible non-repeating key-down events only. A mismatch retries the current key as
    /// a fresh start. At a shared prefix, scope/mode and rule order choose
    /// between completing a shortcut and waiting for another key.
    public mutating func receive(
      _ signature: Signature, at time: Duration, frontmostBundleIdentifier: String?, enabledModeIDs: [String] = [],
    ) -> SequenceMatch {
      receiveDecision(signature, at: time, frontmostBundleIdentifier: frontmostBundleIdentifier,
                      enabledModeIDs: enabledModeIDs).match
    }

    /// Reports how the host should handle a non-repeating key-down alongside the match.
    /// It does not post events, run workflows, or change previously handled keys.
    public mutating func receiveDecision(
      _ signature: Signature, at time: Duration, frontmostBundleIdentifier: String?, enabledModeIDs: [String] = [],
    ) -> Decision {
      if let lastInput,
         time < lastInput || time - lastInput >= timeout || app != frontmostBundleIdentifier || modes != enabledModeIDs {
        clearPrefix()
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
        clearPrefix()
      }
      if decision.disposition == .suppress {
        suppressedKeyCodes.insert(signature.keyCode)
      } else {
        suppressedKeyCodes.remove(signature.keyCode)
      }
      return decision
    }

    /// Pair a release with its key-down even if modifier flags or focus changed.
    /// Releasing a prefix key does not end the pending shortcut sequence.
    public mutating func release(keyCode: UInt16) -> Decision.Disposition {
      suppressedKeyCodes.remove(keyCode) == nil ? .passThrough : .suppress
    }

    /// Clear the sequence and key pairings when the host loses the input stream,
    /// such as on tap disruption or capture handoff.
    public mutating func reset() {
      clearPrefix()
      suppressedKeyCodes.removeAll(keepingCapacity: true)
    }

    private mutating func clearPrefix() {
      prefix.removeAll(keepingCapacity: true)
      lastInput = nil
      app = nil
      modes = []
    }
  }
}

public extension KeyboardTriggers {
  struct SequenceSession: Sendable {
    private let matcher: Matcher
    private let timeout: Duration
    private var prefix: [Signature] = []
    private var lastInput: Duration?
    private var app: String?
    private var modes: [String] = []
    private var suppressedKeyCodes: Set<UInt16> = []
    private var repeating: RepeatBinding?
    private var pendingHold: PendingHold?

    private struct RepeatBinding: Sendable {
      let signature: Signature
      let workflowID: String
      let app: String?
      let modes: [String]
    }

    private struct PendingHold: Sendable {
      let keyCode: UInt16
      let workflowID: String
      let startedAt: Duration
      let deadline: Duration
      let app: String?
      let modes: [String]
    }

    /// The timeout is measured between consecutive keys using caller-supplied monotonic time.
    public init(matcher: Matcher, timeout: Duration) {
      self.matcher = matcher
      self.timeout = timeout
    }

    /// Feed eligible non-repeating key-down events only. A mismatch retries the current key as
    /// a fresh start. At a shared prefix, scope/mode and rule order choose
    /// between completing a shortcut and waiting for another key.
    /// Use `receiveDecision` when the caller needs to schedule holds.
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
      repeating = nil
      pendingHold = nil
      if let lastInput,
         time < lastInput || time - lastInput >= timeout || app != frontmostBundleIdentifier || modes != enabledModeIDs {
        clearPrefix()
      }

      prefix.append(signature)
      var result = matcher.matchSequence(prefix, frontmostBundleIdentifier: frontmostBundleIdentifier,
                                         enabledModeIDs: enabledModeIDs)
      if result.decision.match == .noMatch, prefix.count > 1 {
        prefix = [signature]
        result = matcher.matchSequence(prefix, frontmostBundleIdentifier: frontmostBundleIdentifier,
                                       enabledModeIDs: enabledModeIDs)
      }

      let decision = result.decision
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
      if let rule = result.rule, case let .exact(workflowID) = decision.match {
        if rule.continuation.isEmpty, !rule.endsWithAnyKey, let duration = rule.holdDuration, duration > .zero {
          let deadline = time + duration
          pendingHold = .init(keyCode: signature.keyCode, workflowID: workflowID, startedAt: time,
                              deadline: deadline, app: frontmostBundleIdentifier, modes: enabledModeIDs)
          return Decision(match: .noMatch, disposition: decision.disposition, holdDeadline: deadline)
        }
        if rule.allowRepeat {
          repeating = .init(signature: signature, workflowID: workflowID, app: frontmostBundleIdentifier, modes: enabledModeIDs)
        }
      }
      return decision
    }

    /// Delivers the pending hold at most once. The host owns the timer.
    public mutating func completeHold(
      at time: Duration, frontmostBundleIdentifier: String?, enabledModeIDs: [String] = [],
    ) -> String? {
      guard let pendingHold else { return nil }
      guard time >= pendingHold.startedAt, pendingHold.app == frontmostBundleIdentifier,
            pendingHold.modes == enabledModeIDs else {
        cancelHold()
        return nil
      }
      guard time >= pendingHold.deadline else { return nil }
      cancelHold()
      return pendingHold.workflowID
    }

    /// Cancel a pending hold on modifier changes without forgetting key-up disposition.
    public mutating func cancelHold() {
      pendingHold = nil
    }

    /// Repeats only the last completed binding, with unchanged flags and scope.
    /// A repeat never starts, advances, or extends a pending sequence.
    public mutating func receiveRepeat(
      _ signature: Signature, frontmostBundleIdentifier: String?, enabledModeIDs: [String] = [],
    ) -> Decision {
      let disposition: Decision.Disposition = suppressedKeyCodes.contains(signature.keyCode) ? .suppress : .passThrough
      guard let repeating else { return Decision(match: .noMatch, disposition: disposition) }
      if repeating.app != frontmostBundleIdentifier || repeating.modes != enabledModeIDs
        || (repeating.signature.keyCode == signature.keyCode && repeating.signature != signature) {
        self.repeating = nil
        return Decision(match: .noMatch, disposition: disposition)
      }
      let match: SequenceMatch = repeating.signature == signature ? .exact(repeating.workflowID) : .noMatch
      return Decision(match: match, disposition: disposition)
    }

    /// Pair a release with its key-down even if modifier flags or focus changed.
    /// Releasing a prefix key does not end the pending shortcut sequence.
    public mutating func release(keyCode: UInt16) -> Decision.Disposition {
      if repeating?.signature.keyCode == keyCode { repeating = nil }
      if pendingHold?.keyCode == keyCode { cancelHold() }
      return suppressedKeyCodes.remove(keyCode) == nil ? .passThrough : .suppress
    }

    /// Clear the sequence and key pairings when the host loses the input stream,
    /// such as on tap disruption or capture handoff.
    public mutating func reset() {
      clearPrefix()
      suppressedKeyCodes.removeAll(keepingCapacity: true)
      repeating = nil
      cancelHold()
    }

    private mutating func clearPrefix() {
      prefix.removeAll(keepingCapacity: true)
      lastInput = nil
      app = nil
      modes = []
    }
  }
}

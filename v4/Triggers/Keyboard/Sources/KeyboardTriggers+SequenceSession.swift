public extension KeyboardTriggers {
  struct SequenceSession: Sendable {
    private let matcher: Matcher
    private let timeout: Duration
    private let useLegacyFunctionKeyFallback: Bool
    private var prefix: [Signature] = []
    private var lastInput: Duration?
    private var app: String?
    private var modes: [String] = []
    private var suppressedKeyCodes: Set<UInt16> = []
    private var repeating: RepeatBinding?
    private var pendingHold: PendingHold?
    private var pendingRelease: PendingRelease?
    private var heldPrefix: HeldPrefix?
    private var leader: LeaderPrefix?
    private static let leaderGrace = Duration.milliseconds(100)

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

    private struct PendingRelease: Sendable {
      let keyCode: UInt16
      let workflowID: String
      let startedAt: Duration
      let minimumHold: Duration
    }

    private struct HeldPrefix: Sendable {
      let keyCode: UInt16
      let readyAt: Duration
    }

    private struct LeaderPrefix: Sendable {
      let signature: Signature
      var releasedAt: Duration?
      var used = false
    }

    /// The timeout is measured between consecutive keys using caller-supplied monotonic time.
    public init(matcher: Matcher, timeout: Duration, useLegacyFunctionKeyFallback: Bool = false) {
      self.matcher = matcher
      self.timeout = timeout
      self.useLegacyFunctionKeyFallback = useLegacyFunctionKeyFallback
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
      pendingRelease = nil
      if let lastInput {
        // The hold itself does not use up the time budget for the next key.
        let nextKeyWindow = max(lastInput, heldPrefix?.readyAt ?? lastInput)
        if time < nextKeyWindow || time - nextKeyWindow >= timeout
          || leaderExpired(at: time)
          || app != frontmostBundleIdentifier || modes != enabledModeIDs {
          clearPrefix()
        }
      }

      prefix.append(signature)
      var result = resolve(signature, app: frontmostBundleIdentifier, modes: enabledModeIDs)
      if result.decision.match == .noMatch, prefix.count > 1 {
        clearPrefix()
        prefix = [signature]
        result = resolve(signature, app: frontmostBundleIdentifier, modes: enabledModeIDs)
      }

      let decision = result.decision
      if prefix.count > 1, decision.match != .noMatch { leader?.used = true }
      if decision.match == .partial {
        if prefix.count == 1, let rule = result.rule, !rule.passthrough,
           let duration = rule.holdDuration, duration > .zero {
          heldPrefix = .init(keyCode: signature.keyCode, readyAt: time + duration)
        } else if prefix.count == 1, let rule = result.rule, rule.leaderKey, !rule.passthrough {
          leader = .init(signature: signature)
        }
        lastInput = time
        app = frontmostBundleIdentifier
        modes = enabledModeIDs
      } else if case .exact = decision.match, let leader, leader.releasedAt == nil {
        prefix.removeLast(prefix.count - 1)
        lastInput = time
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
        if let minimumHold = rule.releaseAfter, minimumHold >= .zero {
          pendingRelease = .init(keyCode: signature.keyCode, workflowID: workflowID,
                                 startedAt: time, minimumHold: minimumHold)
        } else if rule.allowRepeat {
          repeating = .init(signature: signature, workflowID: workflowID, app: frontmostBundleIdentifier, modes: enabledModeIDs)
        }
      }
      return decision
    }

    private mutating func resolve(_ signature: Signature, app: String?, modes: [String]) -> (decision: Decision, rule: Rule?) {
      let exact = matcher.matchSequence(prefix, frontmostBundleIdentifier: app, enabledModeIDs: modes)
      guard exact.decision.match == .noMatch, useLegacyFunctionKeyFallback else { return exact }

      let index = prefix.count - 1
      for candidate in signature.functionKeyFallbacks {
        prefix[index] = candidate
        let result = matcher.matchSequence(prefix, frontmostBundleIdentifier: app, enabledModeIDs: modes)
        if result.decision.match != .noMatch { return result }
      }
      prefix[index] = signature
      return exact
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

    /// Cancel pending hold behavior on modifier changes without forgetting key-up disposition.
    public mutating func cancelHold() {
      pendingHold = nil
      if heldPrefix != nil { clearPrefix() }
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
    /// Releasing an ordinary prefix key does not end the pending sequence.
    public mutating func release(keyCode: UInt16) -> Decision.Disposition {
      finishRelease(keyCode: keyCode, at: nil).disposition
    }

    /// Returns the follow-up for the matching key, strictly after the minimum hold.
    /// Focus may change during the press (for example, when peeking another app).
    public mutating func releaseDecision(keyCode: UInt16, at time: Duration) -> Decision {
      finishRelease(keyCode: keyCode, at: time)
    }

    /// Returns an unused leader tap at most once. The host owns the timer and
    /// must service due replays before routing later key-downs.
    public mutating func completeLeaderTap(
      at time: Duration, frontmostBundleIdentifier: String?, enabledModeIDs: [String] = [],
    ) -> Signature? {
      guard let leader, !leader.used, let releasedAt = leader.releasedAt,
            let deadline = leaderReplayDeadline else { return nil }
      guard time >= releasedAt, app == frontmostBundleIdentifier, modes == enabledModeIDs else {
        clearPrefix()
        return nil
      }
      guard time >= deadline else { return nil }

      clearPrefix()
      return leader.signature
    }

    private mutating func finishRelease(keyCode: UInt16, at time: Duration?) -> Decision {
      if repeating?.signature.keyCode == keyCode { repeating = nil }
      if pendingHold?.keyCode == keyCode { cancelHold() }
      if heldPrefix?.keyCode == keyCode { clearPrefix() }
      var replayDeadline: Duration?
      if leader?.signature.keyCode == keyCode, leader?.releasedAt == nil {
        if let time, let lastInput, time >= lastInput {
          leader?.releasedAt = time
          replayDeadline = leaderReplayDeadline
        } else {
          clearPrefix()
        }
      }
      let disposition: Decision.Disposition = suppressedKeyCodes.remove(keyCode) == nil ? .passThrough : .suppress
      guard let pendingRelease, pendingRelease.keyCode == keyCode else {
        return Decision(match: .noMatch, disposition: disposition, leaderReplayDeadline: replayDeadline)
      }

      self.pendingRelease = nil
      let match: SequenceMatch = if let time, time >= pendingRelease.startedAt, time - pendingRelease.startedAt > pendingRelease.minimumHold {
        .exact(pendingRelease.workflowID)
      } else {
        .noMatch
      }
      return Decision(match: match, disposition: disposition, leaderReplayDeadline: replayDeadline)
    }

    /// Clear the sequence and key pairings when the host loses the input stream,
    /// such as on tap disruption or capture handoff.
    public mutating func reset() {
      clearPrefix()
      suppressedKeyCodes.removeAll(keepingCapacity: true)
      repeating = nil
      pendingRelease = nil
      cancelHold()
    }

    private mutating func clearPrefix() {
      prefix.removeAll(keepingCapacity: true)
      lastInput = nil
      app = nil
      modes = []
      heldPrefix = nil
      leader = nil
    }

    private func leaderExpired(at time: Duration) -> Bool {
      guard let releasedAt = leader?.releasedAt else { return false }

      return time < releasedAt || time - releasedAt >= Self.leaderGrace
    }

    private var leaderReplayDeadline: Duration? {
      guard let leader, !leader.used, let releasedAt = leader.releasedAt, let lastInput else { return nil }

      return max(releasedAt, min(releasedAt + Self.leaderGrace, lastInput + timeout))
    }
  }
}

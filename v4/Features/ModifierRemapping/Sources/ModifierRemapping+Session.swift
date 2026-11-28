public extension ModifierRemapping {
  /// Opt-in value state for one dual-role key. A host supplies monotonic time
  /// and applies the logical transitions; this session never posts events.
  struct Session: Sendable {
    public private(set) var rule: Rule?
    private var state: State = .idle
    private var discardedReleases: Set<UInt16> = []
    private var physicallyHeldKeys: Set<UInt16> = []

    private enum State: Sendable {
      case idle
      case pending(since: Duration)
      case holding
    }

    public init(rule: Rule? = nil) {
      self.rule = rule
    }

    public var holdDeadline: Duration? {
      guard let rule, case .pending(let start) = state else { return nil }
      return start + rule.holdDuration
    }

    /// Commits a pending hold at the deadline even if no further key arrives.
    public mutating func advance(to time: Duration) -> [Event] {
      guard let deadline = holdDeadline, time >= deadline else { return [] }
      return beginHold()
    }

    public mutating func receive(_ event: Event, at time: Duration) -> Decision {
      switch event.phase {
      case .down, .repeated: physicallyHeldKeys.insert(event.keyCode)
      case .up: physicallyHeldKeys.remove(event.keyCode)
      }
      let due = advance(to: time)
      if discardedReleases.contains(event.keyCode) {
        if event.phase != .repeated { discardedReleases.remove(event.keyCode) }
        // A fresh down can follow a release lost during a stream disruption.
        if event.phase != .down { return .init(output: due, forwardsInput: false) }
      }
      guard let rule else { return .init(output: due, forwardsInput: true) }
      let modifier = rule.modifier.keyCode
      guard event.keyCode == modifier else {
        let chord = event.phase == .down ? beginHold() : []
        return .init(output: due + chord, forwardsInput: true)
      }

      switch (state, event.phase) {
      case (.idle, .down):
        state = .pending(since: time)
      case (.idle, .up), (.idle, .repeated):
        return .init(output: due, forwardsInput: true)
      case (.pending(let start), .up):
        state = .idle
        guard time >= start, !physicallyHeldKeys.contains(rule.tapKeyCode) else {
          return .init(output: due, forwardsInput: false)
        }
        return .init(output: [.init(keyCode: rule.tapKeyCode, phase: .down),
                              .init(keyCode: rule.tapKeyCode, phase: .up)], forwardsInput: false)
      case (.holding, .up):
        state = .idle
        return .init(output: due + [.init(keyCode: modifier, phase: .up)], forwardsInput: false)
      default:
        break
      }
      return .init(output: due, forwardsInput: false)
    }

    /// Discard pending taps and forget observed key state after losing the
    /// input stream. Release a modifier only if its logical down was emitted,
    /// and suppress the old physical up if it still arrives.
    public mutating func reset() -> [Event] {
      physicallyHeldKeys.removeAll(keepingCapacity: true)
      return cancelPress()
    }

    /// Reset the old rule before changing it. The caller must apply any cleanup.
    public mutating func updateRule(_ rule: Rule?) -> [Event] {
      guard self.rule != rule else { return [] }
      let cleanup = cancelPress()
      self.rule = rule
      return cleanup
    }

    private mutating func cancelPress() -> [Event] {
      guard let modifier = rule?.modifier.keyCode else { return [] }
      defer { state = .idle }
      switch state {
      case .idle: return []
      case .pending:
        discardedReleases.insert(modifier)
        return []
      case .holding:
        discardedReleases.insert(modifier)
        return [.init(keyCode: modifier, phase: .up)]
      }
    }

    private mutating func beginHold() -> [Event] {
      guard let rule, case .pending = state else { return [] }
      state = .holding
      return [.init(keyCode: rule.modifier.keyCode, phase: .down)]
    }
  }
}

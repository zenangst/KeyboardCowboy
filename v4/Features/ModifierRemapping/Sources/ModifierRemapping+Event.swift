public extension ModifierRemapping {
  /// A normalized key transition. Input `.down` represents a fresh physical
  /// press; the caller distinguishes repeats and decodes modifier transitions.
  struct Event: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
      case down, up, repeated
    }

    public let keyCode: UInt16
    public let phase: Phase

    public init(keyCode: UInt16, phase: Phase) {
      self.keyCode = keyCode
      self.phase = phase
    }
  }

  struct Decision: Equatable, Sendable {
    /// Emit these logical transitions in order, before forwarding the input.
    public let output: [Event]
    public let forwardsInput: Bool

    init(output: [Event] = [], forwardsInput: Bool) {
      self.output = output
      self.forwardsInput = forwardsInput
    }
  }
}

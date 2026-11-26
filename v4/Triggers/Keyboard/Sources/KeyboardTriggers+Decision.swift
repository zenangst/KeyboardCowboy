public extension KeyboardTriggers {
  struct Decision: Equatable, Sendable {
    public enum Disposition: Equatable, Sendable {
      case passThrough
      case suppress
    }

    public let match: SequenceMatch
    public let disposition: Disposition
    /// A pending hold instead of an immediate match, in the caller's monotonic clock.
    public let holdDeadline: Duration?
    /// When the host may ask to replay an unused leader tap.
    public let leaderReplayDeadline: Duration?

    init(match: SequenceMatch, disposition: Disposition, holdDeadline: Duration? = nil,
         leaderReplayDeadline: Duration? = nil) {
      self.match = match
      self.disposition = disposition
      self.holdDeadline = holdDeadline
      self.leaderReplayDeadline = leaderReplayDeadline
    }

    static let noMatch = Self(match: .noMatch, disposition: .passThrough)
  }
}

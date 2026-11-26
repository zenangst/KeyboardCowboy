public extension KeyboardTriggers {
  struct Decision: Equatable, Sendable {
    public enum Disposition: Equatable, Sendable {
      case passThrough
      case suppress
    }

    public let match: SequenceMatch
    public let disposition: Disposition

    static let noMatch = Self(match: .noMatch, disposition: .passThrough)
  }
}

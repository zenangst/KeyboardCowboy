public extension KeyboardTriggers {
  enum SequenceMatch: Equatable, Sendable {
    case noMatch
    case partial
    case exact(String)
  }
}

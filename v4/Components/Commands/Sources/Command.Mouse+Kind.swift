public extension Command.Mouse {
  enum Kind: Codable, Hashable, Sendable {
    case click(Target)
    case doubleClick(Target)
    case rightClick(Target)
  }
}

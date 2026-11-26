public extension Command.Mouse {
  enum Target: Codable, Hashable, Sendable {
    case focused(Anchor)
  }
}

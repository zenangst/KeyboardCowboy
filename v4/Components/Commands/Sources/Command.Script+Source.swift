public extension Command.Script {
  enum Source: Codable, Hashable, Sendable {
    case inline(String)
    case path(String)
  }
}

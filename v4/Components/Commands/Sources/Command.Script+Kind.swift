public extension Command.Script {
  enum Kind: Codable, Hashable, Sendable {
    case appleScript(variant: Variant)
    case shellScript
  }
}

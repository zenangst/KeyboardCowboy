extension ScriptCommand {
  enum Kind: Hashable, Codable, Sendable {
    case appleScript(variant: Variant)
    case shellScript

    var rawValue: String {
      switch self {
      case .appleScript: "scpt"
      case .shellScript: "sh"
      }
    }
  }
}

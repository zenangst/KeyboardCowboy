extension ScriptCommand {
  enum Kind: String, Codable, Sendable {
    case appleScript = "scpt"
    case shellScript = "sh"
  }
}

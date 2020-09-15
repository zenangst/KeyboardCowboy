import Cocoa

public enum ModifierKey: String, CaseIterable, Codable, Hashable {
  case shift = "$"
  case control = "^"
  case option = "~"
  case command = "@"

  var pretty: String {
    switch self {
    case .shift:
      return "⇧"
    case .control:
      return "⌃"
    case .option:
      return "⌥"
    case .command:
      return "⌘"
    }
  }

  var modifierFlags: NSEvent.ModifierFlags {
    switch self {
    case .shift:
      return .shift
    case .control:
      return .control
    case .option:
      return .option
    case .command:
      return .command
    }
  }
}

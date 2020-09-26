import Cocoa

public enum ModifierKey: String, CaseIterable, Codable, Hashable {
  case shift = "$"
  case control = "^"
  case option = "~"
  case command = "@"
  case function = "fn"

  public var pretty: String {
    switch self {
    case .shift:
      return "⇧"
    case .control:
      return "⌃"
    case .option:
      return "⌥"
    case .command:
      return "⌘"
    case .function:
      return "fn"
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
    case .function:
      return .function
    }
  }
}

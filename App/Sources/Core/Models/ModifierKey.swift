import Carbon
import Cocoa
import KeyCodes

public enum ModifierKey: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
  public var id: String { return rawValue }

  case shift = "$"
  case function = "fn"
  case control = "^"
  case option = "~"
  case command = "@"

  public var symbol: String {
    switch self {
    case .function:
      return "globe"
    case .shift:
      return ""
    case .control:
      return ""
    case .option:
      return ""
    case .command:
      return ""
    }
  }

  public var writtenValue: String {
    switch self {
    case .function, .shift:
      return ""
    case .control:
      return "control"
    case .option:
      return "option"
    case .command:
      return "command"
    }
  }

  public var keyValue: String {
    switch self {
    case .function:
      return "fn"
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

  public var pretty: String {
    switch self {
    case .function:
      return "ƒ"
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

  public var cgModifierFlags: CGEventFlags {
    switch self {
    case .shift:
      return .maskShift
    case .control:
      return .maskControl
    case .option:
      return .maskAlternate
    case .command:
      return .maskCommand
    case .function:
      return .maskSecondaryFn
    }
  }
}

import Carbon
import Cocoa
import KeyCodes

public enum ModifierKey: String, Codable, Hashable, Identifiable, Sendable {
  public var id: String { return rawValue }

  case shift = "$"
  case function = "fn"
  case control = "^"
  case option = "~"
  case command = "@"
  case capsLock = "⇪"

  public static var allCases: [ModifierKey] {
    return [.function, .shift, .control, .option, .command]
  }

  public var symbol: String {
    switch self {
    case .function: "globe"
    case .shift: ""
    case .control: ""
    case .option: ""
    case .command: ""
    case .capsLock: ""
    }
  }

  public var writtenValue: String {
    switch self {
    case .function, .shift: ""
    case .control:          "control"
    case .option:           "option"
    case .command:          "command"
    case .capsLock:         "caps lock"
    }
  }

  public var keyValue: String {
    switch self {
    case .function: "fn"
    case .shift:    "⇧"
    case .control:  "⌃"
    case .option:   "⌥"
    case .command:  "⌘"
    case .capsLock: "⇪"
    }
  }

  public var pretty: String {
    switch self {
    case .function:"ƒ"
    case .shift:   "⇧"
    case .control: "⌃"
    case .option:  "⌥"
    case .command: "⌘"
    case .capsLock: "⇪"
    }
  }

  public var cgModifierFlags: CGEventFlags {
    switch self {
    case .shift:    .maskShift
    case .control:  .maskControl
    case .option:   .maskAlternate
    case .command:  .maskCommand
    case .function: .maskSecondaryFn
    case .capsLock: .maskAlphaShift
    }
  }
}

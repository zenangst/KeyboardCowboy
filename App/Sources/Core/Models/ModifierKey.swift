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

  var sortValue: Int {
    switch self {
    case .function: 0
    case .shift: 1
    case .control: 2
    case .option: 3
    case .command: 4
    }
  }

  public var symbol: String {
    switch self {
    case .function: "globe"
    case .shift: ""
    case .control: ""
    case .option: ""
    case .command: ""
    }
  }

  public var writtenValue: String {
    switch self {
    case .function, .shift: ""
    case .control:          "control"
    case .option:           "option"
    case .command:          "command"
    }
  }

  public var keyValue: String {
    switch self {
    case .function: "fn"
    case .shift:    "⇧"
    case .control:  "⌃"
    case .option:   "⌥"
    case .command:  "⌘"
    }
  }

  public var pretty: String {
    switch self {
    case .function:"ƒ"
    case .shift:   "⇧"
    case .control: "⌃"
    case .option:  "⌥"
    case .command: "⌘"
    }
  }

  public var cgModifierFlags: CGEventFlags {
    switch self {
    case .shift:    .maskShift
    case .control:  .maskControl
    case .option:   .maskAlternate
    case .command:  .maskCommand
    case .function: .maskSecondaryFn
    }
  }
}

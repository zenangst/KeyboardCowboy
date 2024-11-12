import Carbon
import Cocoa
import KeyCodes

public enum ModifierKey: String, Codable, Hashable, Identifiable, Sendable {
  public var id: String { return rawValue }

  case function = "fn"
  case capsLock = "⇪"

  case leftShift = "$"
  case leftControl = "^"
  case leftOption = "~"
  case leftCommand = "@"

  case rightShift = "r$"
  case rightControl = "r^"
  case rightOption = "r~"
  case rightCommand = "r@"

  public static var leftModifiers: [ModifierKey] {
    [.leftShift, .leftControl, .leftOption, .leftCommand]
  }

  public static var rightModifiers: [ModifierKey] {
    [.rightShift, .rightControl, .rightOption, .rightCommand]
  }

  public static var allCases: [ModifierKey] {
    return [
      .function,
      .leftShift,
      .rightShift,
      .leftControl,
      .rightControl,
      .leftOption,
      .rightOption,
      .leftCommand,
      .rightCommand,
      .capsLock
    ]
  }

  public var symbol: String {
    switch self {
    case .function: "globe"
    case .leftShift, .rightShift: ""
    case .leftCommand, .rightCommand: ""
    case .leftOption, .rightOption: ""
    case .leftControl, .rightControl: ""
    case .capsLock: ""
    }
  }

  public var writtenValue: String {
    switch self {
    case .function, .leftShift, .rightShift: ""
    case .leftControl, .rightControl:        "control"
    case .leftOption, .rightOption:          "option"
    case .leftCommand, .rightCommand:        "command"
    case .capsLock:         ""
    }
  }

  public var keyValue: String {
    switch self {
    case .function:     "fn"
    case .leftShift:    "⇧"
    case .rightShift:   "⇧"
    case .leftControl, .rightControl: "⌃"
    case .leftOption, .rightOption:   "⌥"
    case .leftCommand, .rightCommand: "⌘"
    case .capsLock:     "⇪"
    }
  }

  public var pretty: String {
    switch self {
    case .function:"ƒ"
    case .leftShift, .rightShift:   "⇧"
    case .leftControl, .rightControl: "⌃"
    case .leftOption, .rightOption:  "⌥"
    case .leftCommand, .rightCommand: "⌘"
    case .capsLock: "⇪"
    }
  }

  public var cgEventFlags: CGEventFlags {
    var modifierFlags = CGEventFlags.maskNonCoalesced
    switch self {
    case .leftShift:
      modifierFlags.insert(.maskShift)
      modifierFlags.insert(.maskLeftShift)
    case .rightShift:
      modifierFlags.insert(.maskShift)
      modifierFlags.insert(.maskRightShift)
    case .leftControl:
      modifierFlags.insert(.maskControl)
      modifierFlags.insert(.maskLeftControl)
    case .rightControl:
      modifierFlags.insert(.maskControl)
      modifierFlags.insert(.maskRightControl)
    case .leftOption:
      modifierFlags.insert(.maskAlternate)
      modifierFlags.insert(.maskLeftAlternate)
    case .rightOption:
      modifierFlags.insert(.maskAlternate)
      modifierFlags.insert(.maskRightAlternate)
    case .leftCommand:
      modifierFlags.insert(.maskCommand)
      modifierFlags.insert(.maskLeftCommand)
    case .rightCommand:
      modifierFlags.insert(.maskCommand)
      modifierFlags.insert(.maskRightCommand)
    case .function:
      modifierFlags.insert(.maskSecondaryFn)
    case .capsLock:
      modifierFlags.insert(.maskAlphaShift)
    }

    return modifierFlags
  }
}

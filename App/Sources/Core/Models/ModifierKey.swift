import Carbon
import Cocoa
import KeyCodes

public enum ModifierKey: String, Codable, Hashable, Identifiable, Sendable {
  public var id: String { return rawValue }

  var keyCode: Int? {
    switch self {
    case .function: return KeyShortcut.keyCode(for: "fn")
    case .capsLock: return KeyShortcut.keyCode(for: "⇪")
    case .leftShift: return KeyShortcut.keyCode(for: "⇧L")
    case .leftControl: return KeyShortcut.keyCode(for: "⌃L")
    case .leftOption: return KeyShortcut.keyCode(for: "⌥L")
    case .leftCommand: return KeyShortcut.keyCode(for: "⌘L")
    case .rightShift: return KeyShortcut.keyCode(for: "⇧R")
    case .rightControl: return KeyShortcut.keyCode(for: "⌃R")
    case .rightOption: return KeyShortcut.keyCode(for: "⌥R")
    case .rightCommand: return KeyShortcut.keyCode(for: "⌘R")
    }
  }

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

  public var iconValue: String {
    switch self {
    case .function: ""
    case .leftShift, .rightShift: ""
    case .leftControl, .rightControl:        "control"
    case .leftOption, .rightOption:          "option"
    case .leftCommand, .rightCommand:        "command"
    case .capsLock:         ""
    }
  }

  public var writtenValue: String {
    switch self {
    case .function: "function"
    case .leftShift, .rightShift: "shift"
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

  public var key: Int {
    switch self {
    case .function: return kVK_Function   // Fn key
    case .capsLock: return kVK_CapsLock  // Caps Lock key

    case .leftShift: return kVK_Shift    // Left Shift key
    case .rightShift: return kVK_RightShift // Right Shift key

    case .leftControl: return kVK_Control  // Left Control key
    case .rightControl: return kVK_RightControl // Right Control key

    case .leftOption: return kVK_Option  // Left Option (Alt) key
    case .rightOption: return kVK_RightOption // Right Option (Alt) key

    case .leftCommand: return kVK_Command // Left Command (⌘) key
    case .rightCommand: return kVK_RightCommand // Right Command (⌘) key
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

  var pair: ModifierKey? {
    switch self {
    case .function: nil
    case .capsLock: nil
    case .leftShift:    .rightShift
    case .leftControl:  .rightControl
    case .leftOption:   .rightOption
    case .leftCommand:  .rightCommand
    case .rightShift:   .leftShift
    case .rightControl: .leftControl
    case .rightOption:  .leftOption
    case .rightCommand: .leftCommand
    }
  }

  init(keyCode: Int) {
    switch keyCode {
    case kVK_Function: self = .function
    case kVK_CapsLock: self = .capsLock

    case kVK_Shift: self = .leftShift
    case kVK_RightShift: self = .rightShift

    case kVK_Control: self = .leftControl
    case kVK_RightControl: self = .rightControl

    case kVK_Option: self = .leftOption
    case kVK_RightOption: self = .rightOption

    case kVK_Command: self = .leftCommand
    case kVK_RightCommand: self = .rightCommand

    default:
      fatalError("Invalid keyCode \(keyCode) for ModifierKey initialization")
    }
  }
}

extension Array<ModifierKey> {
  var keyCode: Int? {
    if count == 1 { return self[0].keyCode }
    return compactMap(\.keyCode).reduce(-255, +)
  }

  var cgModifiers: CGEventFlags {
    var flags = CGEventFlags.maskNonCoalesced
    self.forEach { flags.insert($0.cgEventFlags) }
    return flags
  }
}

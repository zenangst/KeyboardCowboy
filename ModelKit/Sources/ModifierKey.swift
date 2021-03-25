import Cocoa

public enum ModifierKey: String, CaseIterable, Codable, Hashable, Identifiable {
  public var id: String { return rawValue }

  case shift = "$"
  case function = "fn"
  case control = "^"
  case option = "~"
  case command = "@"

  public static func fromNSEvent(_ eventModifierFlags: NSEvent.ModifierFlags) -> [ModifierKey] {
    ModifierKey.allCases
      .compactMap { eventModifierFlags.contains($0.modifierFlags) ? $0 : nil }
  }

  public static func fromCGEvent(_ flags: CGEventFlags) -> [ModifierKey] {
    var modifiers = [ModifierKey]()

    if flags.contains(.maskShift) { modifiers.append(.shift) }
    if flags.contains(.maskControl) { modifiers.append(.control) }
    if flags.contains(.maskAlternate) { modifiers.append(.option) }
    if flags.contains(.maskCommand) { modifiers.append(.command) }
    if flags.contains(.maskSecondaryFn) { modifiers.append(.function) }

    return modifiers
  }

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

  public var modifierFlags: NSEvent.ModifierFlags {
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

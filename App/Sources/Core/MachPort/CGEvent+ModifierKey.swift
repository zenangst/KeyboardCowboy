import AppKit

extension CGEvent {
  var modifierKeys: [ModifierKey] { flags.modifierKeys }
}

extension CGEventFlags {
  private static let knownFlags: [CGEventFlags] = [
    .maskAlphaShift,
    .maskShift,
    .maskLeftShift,
    .maskRightShift,
    .maskControl,
    .maskLeftControl,
    .maskRightControl,
    .maskAlternate,
    .maskLeftAlternate,
    .maskRightAlternate,
    .maskCommand,
    .maskLeftCommand,
    .maskRightCommand,
    .maskHelp,
    .maskSecondaryFn,
    .maskNumericPad,
    .maskNonCoalesced
  ]

  var modifierKeys: [ModifierKey] {
    var modifiers = [ModifierKey]()

    // Handle Shift
    if contains(.maskShift) {
      if contains(.maskLeftShift)  { modifiers.append(.leftShift) }
      if contains(.maskRightShift) { modifiers.append(.rightShift) }
    }

    // Handle Control
    if contains(.maskControl) {
      if contains(.maskLeftControl)  { modifiers.append(.leftControl) }
      if contains(.maskRightControl) { modifiers.append(.rightControl) }
    }

    // Handle Option
    if contains(.maskAlternate) {
      if contains(.maskLeftAlternate)  { modifiers.append(.leftOption) }
      if contains(.maskRightAlternate) { modifiers.append(.rightOption) }
    }

    // Handle Command
    if contains(.maskCommand) {
      if contains(.maskLeftCommand)  { modifiers.append(.leftCommand) }
      if contains(.maskRightCommand) { modifiers.append(.rightCommand) }
    }

    // Handle Caps Lock
    if contains(.maskAlphaShift) {
      modifiers.append(.capsLock)
    }

    // Handle Function
    if contains(.maskSecondaryFn) {
      modifiers.append(.function)
    }

    return modifiers
  }

  var remainingFlags: UInt64 {
    var rawValue = rawValue
    for flag in Self.knownFlags {
      if rawValue & flag.rawValue != 0 { rawValue -= flag.rawValue }
    }
    return self.rawValue - rawValue
  }

  static var maskLeftShift: CGEventFlags { CGEventFlags(rawValue: UInt64(NX_DEVICELSHIFTKEYMASK)) }
  static var maskLeftControl: CGEventFlags { CGEventFlags(rawValue: UInt64(NX_DEVICELCTLKEYMASK)) }
  static var maskLeftAlternate: CGEventFlags { CGEventFlags(rawValue: UInt64(NX_DEVICELALTKEYMASK)) }
  static var maskLeftCommand: CGEventFlags { CGEventFlags(rawValue: UInt64(NX_DEVICELCMDKEYMASK)) }

  static var maskRightControl: CGEventFlags { CGEventFlags(rawValue: UInt64(NX_DEVICERCTLKEYMASK)) }
  static var maskRightShift: CGEventFlags { CGEventFlags(rawValue: UInt64(NX_DEVICERSHIFTKEYMASK)) }
  static var maskRightAlternate: CGEventFlags { CGEventFlags(rawValue: UInt64(NX_DEVICERALTKEYMASK)) }
  static var maskRightCommand: CGEventFlags { CGEventFlags(rawValue: UInt64(NX_DEVICERCMDKEYMASK)) }
}

import AppKit

extension CGEvent {
  var modifierKeys: [ModifierKey] {
    var modifiers = [ModifierKey]()

    // Handle Shift
    if flags.contains(.maskShift) {
      if flags.contains(.maskLeftShift)  { modifiers.append(.leftShift) }
      if flags.contains(.maskRightShift) { modifiers.append(.rightShift) }
    }

    // Handle Control
    if flags.contains(.maskControl) {
      if flags.contains(.maskLeftControl)  { modifiers.append(.leftControl) }
      if flags.contains(.maskRightControl) { modifiers.append(.rightControl) }
    }

    // Handle Option
    if flags.contains(.maskAlternate) {
      if flags.contains(.maskLeftAlternate)  { modifiers.append(.leftOption) }
      if flags.contains(.maskRightAlternate) { modifiers.append(.rightOption) }
    }

    // Handle Command
    if flags.contains(.maskCommand) {
      if flags.contains(.maskLeftCommand)  { modifiers.append(.leftCommand) }
      if flags.contains(.maskRightCommand) { modifiers.append(.rightCommand) }
    }

    // Handle Caps Lock
    if flags.contains(.maskAlphaShift) {
      modifiers.append(.capsLock)
    }

    // Handle Function
    if flags.contains(.maskSecondaryFn) {
      modifiers.append(.function)
    }

    return modifiers
  }
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

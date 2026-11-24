import Carbon
import CoreGraphics
import IOKit.hidsystem
import KeyCodeSystem
import MachPortSystem

public extension Keyboard {
  /// Resolves a routed, non-repeating key-down without retaining the event.
  /// The host decides when recording is active and how to handle editing keys.
  static func captureShortcut(
    from event: MachPortSystem.EventSnapshot, layout: KeyCodeSystem.Layout,
  ) -> Shortcut? {
    guard event.typeRawValue == CGEventType.keyDown.rawValue, !event.isRepeat,
          let code = Int(exactly: event.keyCode),
          let label = layout.displayValue(for: code) else { return nil }

    let flags = CGEventFlags(rawValue: event.flagsRawValue)
    var modifiers: [Modifier] = []
    func append(_ generic: CGEventFlags, _ leftMask: Int32, _ rightMask: Int32, _ left: Modifier, _ right: Modifier) {
      let hasLeft = flags.contains(CGEventFlags(rawValue: UInt64(leftMask)))
      let hasRight = flags.contains(CGEventFlags(rawValue: UInt64(rightMask)))
      if hasLeft || (!hasRight && flags.contains(generic)) { modifiers.append(left) }
      if hasRight { modifiers.append(right) }
    }
    append(.maskShift, NX_DEVICELSHIFTKEYMASK, NX_DEVICERSHIFTKEYMASK, .leftShift, .rightShift)
    append(.maskControl, NX_DEVICELCTLKEYMASK, NX_DEVICERCTLKEYMASK, .leftControl, .rightControl)
    append(.maskAlternate, NX_DEVICELALTKEYMASK, NX_DEVICERALTKEYMASK, .leftOption, .rightOption)
    append(.maskCommand, NX_DEVICELCMDKEYMASK, NX_DEVICERCMDKEYMASK, .leftCommand, .rightCommand)
    if flags.contains(.maskAlphaShift) { modifiers.append(.capsLock) }
    if flags.contains(.maskSecondaryFn),
       KeyCodeSystem.specialKeys[code] == nil || code == kVK_Space || code == kVK_Tab || code == kVK_Escape {
      modifiers.append(.function)
    }
    return Shortcut(key: label, modifiers: modifiers)
  }
}

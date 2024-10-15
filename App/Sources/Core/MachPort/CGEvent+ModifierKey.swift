import AppKit

extension CGEvent {
  var modifierKeys: [ModifierKey] {
    var modifiers = [ModifierKey]()

    if flags.contains(.maskShift) { modifiers.append(.shift) }
    if flags.contains(.maskControl) { modifiers.append(.control) }
    if flags.contains(.maskAlternate) { modifiers.append(.option) }
    if flags.contains(.maskCommand) { modifiers.append(.command) }
    if flags.contains(.maskAlphaShift) { modifiers.append(.capsLock) }
    if flags.contains(.maskSecondaryFn) { modifiers.append(.function) }

    return modifiers
  }
}

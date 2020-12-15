import Cocoa
import ModelKit

extension CGEventFlags {
  func isEqualTo(_ modifiers: [ModifierKey]) -> Bool {
    var collectedModifiers = Set<ModifierKey>()

    if contains(.maskShift) { collectedModifiers.insert(.shift) }
    if contains(.maskControl) { collectedModifiers.insert(.control) }
    if contains(.maskAlternate) { collectedModifiers.insert(.option) }
    if contains(.maskCommand) { collectedModifiers.insert(.command) }
    if contains(.maskSecondaryFn) { collectedModifiers.insert(.function) }

    let modifierSet = Set<ModifierKey>(modifiers)
    return collectedModifiers == modifierSet
  }

  var isEmpty: Bool {
    isDisjoint(with: [
      .maskControl, .maskCommand, .maskAlternate, .maskShift, .maskSecondaryFn
    ])
  }
}

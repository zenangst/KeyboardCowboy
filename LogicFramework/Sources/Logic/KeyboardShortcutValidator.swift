import BridgeKit
import Cocoa
import Carbon.HIToolbox
import Foundation
import ModelKit

public class KeyboardShortcutValidator {
  private let blockedKeyCodes = [36, 51, 53, 117] // ↩, ⌫, ⎋, ⌦
  private let keycodeMapper: KeyCodeMapping
  private var systemKeyboardShortcuts = [KeyboardShortcut]()

  public init(keycodeMapper: KeyCodeMapping) {
    self.keycodeMapper = keycodeMapper
    self.systemKeyboardShortcuts = getSystemShortcuts()
  }

  private func getSystemShortcuts() -> [KeyboardShortcut] {
    var result = [KeyboardShortcut]()
    var shortcutsUnmanaged: Unmanaged<CFArray>?
    guard
      CopySymbolicHotKeys(&shortcutsUnmanaged) == noErr,
      let shortcuts = shortcutsUnmanaged?.takeRetainedValue() as? [[String: Any]]
    else {
      assertionFailure("Could not get system keyboard shortcuts")
      return []
    }

    for shortcut in shortcuts {
      guard
        (shortcut[kHISymbolicHotKeyEnabled] as? Bool) == true,
        let carbonKeyCode = shortcut[kHISymbolicHotKeyCode] as? Int,
        let carbonModifiers = shortcut[kHISymbolicHotKeyModifiers] as? Int,
        let key = try? keycodeMapper.map(carbonKeyCode, modifiers: carbonModifiers)
      else {
        continue
      }

      let nsEventFlags = NSEvent.ModifierFlags(carbon: carbonModifiers)
      let modifiers = ModifierKey.fromNSEvent(nsEventFlags)
      let keyboardShortcut = KeyboardShortcut(key: key, modifiers: modifiers)
      result.append(keyboardShortcut)
    }

    return result
  }

  func validate(_ context: HotKeyContext) -> KeyboardShortcutValidationContext {
    guard let key = try? keycodeMapper.map(Int(context.keyCode), modifiers: 0) else {
      return .invalid(.empty())
    }
    let validationContext: KeyboardShortcutValidationContext
    var keyboardShortcut: KeyboardShortcut
    let modifiers = ModifierKey.fromCGEvent(context.event.flags)
    keyboardShortcut = KeyboardShortcut(
      id: UUID().uuidString,
      key: key,
      modifiers: modifiers)

    let systemKeyboardShortcut = systemKeyboardShortcuts
      .first(where: { $0.key == keyboardShortcut.key &&
              $0.modifiers == keyboardShortcut.modifiers })
    if let systemKeyboardShortcut = systemKeyboardShortcut {
      validationContext = .invalid(systemKeyboardShortcut)
    } else if blockedKeyCodes.contains(Int(context.keyCode)) {
      validationContext = .invalid(keyboardShortcut)
    } else {
      validationContext = .valid(keyboardShortcut)
    }

    return validationContext
  }
}

private extension NSEvent.ModifierFlags {
  var carbon: Int {
    var modifierFlags = 0

    if contains(.control) { modifierFlags |= controlKey }
    if contains(.option) { modifierFlags |= optionKey }
    if contains(.shift) { modifierFlags |= shiftKey }
    if contains(.command) { modifierFlags |= cmdKey }

    return modifierFlags
  }

  init(carbon: Int) {
    self.init()

    if carbon & controlKey == controlKey { insert(.control) }
    if carbon & optionKey == optionKey { insert(.option) }
    if carbon & shiftKey == shiftKey { insert(.shift) }
    if carbon & cmdKey == cmdKey { insert(.command) }
  }
}

import Foundation
import KeyCodes
import MachPort

final class MachPortRecordValidator {
  let store: KeyCodesStore

  init(store: KeyCodesStore) {
    self.store = store
  }

  func validate(_ machPortEvent: MachPortEvent, allowAllKeys: Bool = false) -> KeyShortcutRecording {
    let keyCode = Int(machPortEvent.keyCode)

    guard let displayValue = store.displayValue(for: keyCode) else {
      return .cancel(.empty())
    }

    let virtualModifiers = VirtualModifierKey.modifiers(for: keyCode, flags: machPortEvent.event.flags, specialKeys: Array(store.specialKeys().keys))
    let modifiers = virtualModifiers.compactMap({ ModifierKey(rawValue: $0.rawValue) })
    let keyboardShortcut = KeyShortcut(
      id: UUID().uuidString,
      key: displayValue,
      modifiers: modifiers
    )

    if allowAllKeys {
      return .valid(keyboardShortcut)
    }

    if let restrictedKeyCode = RestrictedKeyCode(rawValue: keyCode) {
      switch restrictedKeyCode {
      case .backspace, .delete:
        return .delete(keyboardShortcut)
      case .escape:
        return .cancel(keyboardShortcut)
      case .enter:
        return .valid(keyboardShortcut)
      }
    } else {
      return .valid(keyboardShortcut)
    }
  }
}

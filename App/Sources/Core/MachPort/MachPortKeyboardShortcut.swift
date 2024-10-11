import Foundation
import KeyCodes
import MachPort

struct MachPortKeyboardShortcut: Hashable, Identifiable {
  var id: String { original.key + original.modifersDisplayValue + ":" + (original.lhs ? "true" : "false") }

  let original: KeyShortcut
  let uppercase: KeyShortcut
  let lhsAgnostic: KeyShortcut

  init?(_ machPortEvent: MachPortEvent, specialKeys: [Int], store: KeyCodesStore) {
    guard let displayValue = store.displayValue(for: Int(machPortEvent.keyCode)) else {
      return nil
    }

    let modifiers = VirtualModifierKey.fromCGEvent(machPortEvent.event, specialKeys: specialKeys)
      .compactMap({ ModifierKey(rawValue: $0.rawValue) })

    self.original = KeyShortcut(id: UUID().uuidString, key: displayValue, lhs: machPortEvent.lhs, modifiers: modifiers)
    self.uppercase = KeyShortcut(key: displayValue.uppercased(), lhs: machPortEvent.lhs, modifiers: modifiers)
    self.lhsAgnostic = KeyShortcut(key: displayValue, lhs: false, modifiers: modifiers)
  }
}

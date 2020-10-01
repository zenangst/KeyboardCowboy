import Foundation
import LogicFramework
import ViewKit

protocol KeyboardShortcutViewModelMapping {
  func map(_ keyboardShortcut: [KeyboardShortcut]) -> [KeyboardShortcutViewModel]
}

class KeyboardShortcutViewModelMapper: KeyboardShortcutViewModelMapping {
  func map(_ keyboardShortcut: [KeyboardShortcut]) -> [KeyboardShortcutViewModel] {
    keyboardShortcut.compactMap {
      let modifierString: String
      if let modifiers = $0.modifiers {
        modifierString = modifiers.compactMap({ $0.pretty }).joined()
      } else {
        modifierString = ""
      }

      let name = "\(modifierString)\($0.key)"
      return .init(id: $0.id, name: name)
    }
  }
}

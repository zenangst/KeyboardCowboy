import Foundation
import LogicFramework
import ViewKit

protocol KeyboardShortcutViewModelMapping {
  func map(_ keyboardShortcut: [KeyboardShortcut]) -> [KeyboardShortcutViewModel]
}

class KeyboardShortcutViewModelMapper: KeyboardShortcutViewModelMapping {
  func map(_ keyboardShortcut: [KeyboardShortcut]) -> [KeyboardShortcutViewModel] {
    keyboardShortcut.compactMap {
      .init(
        id: $0.id,
        key: $0.key,
        modifiers: $0.modifiers?.swapNamespace ?? [])
    }
  }
}

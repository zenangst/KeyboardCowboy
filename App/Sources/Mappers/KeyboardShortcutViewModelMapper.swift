import Foundation
import LogicFramework
import ViewKit

protocol KeyboardShortcutViewModelMapping {
  func map(_ keyboardShortcuts: [KeyboardShortcut]) -> [KeyboardShortcutViewModel]
}

class KeyboardShortcutViewModelMapper: KeyboardShortcutViewModelMapping {
  func map(_ keyboardShortcuts: [KeyboardShortcut]) -> [KeyboardShortcutViewModel] {
    var models = [KeyboardShortcutViewModel]()
    for (index, keyboardShortcut) in keyboardShortcuts.enumerated() {
      models.append(KeyboardShortcutViewModel(
                      id: keyboardShortcut.id,
                      index: index + 1,
                      key: keyboardShortcut.key,
                      modifiers: keyboardShortcut.modifiers?.swapNamespace ?? []))
    }
    return models
  }
}

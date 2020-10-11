import Foundation
import LogicFramework
import ViewKit

protocol KeyboardShortcutViewModelMapping {
  func map(_ keyboardShortcuts: [KeyboardShortcut]) -> [KeyboardShortcutViewModel]
  func map(_ keyboardShortcuts: KeyboardShortcut, index: Int) -> KeyboardShortcutViewModel
}

class KeyboardShortcutViewModelMapper: KeyboardShortcutViewModelMapping {
  func map(_ keyboardShortcuts: [KeyboardShortcut]) -> [KeyboardShortcutViewModel] {
    var models = [KeyboardShortcutViewModel]()
    for (index, shortcut) in keyboardShortcuts.enumerated() {
      models.append(map(shortcut, index: index + 1))
    }
    return models
  }

  func map(_ keyboardShortcut: KeyboardShortcut, index: Int) -> KeyboardShortcutViewModel {
    .init(
      id: keyboardShortcut.id,
      index: index,
      key: keyboardShortcut.key,
      modifiers: keyboardShortcut.modifiers?.swapNamespace ?? [])
  }
}

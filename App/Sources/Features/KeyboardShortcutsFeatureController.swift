import Foundation
import LogicFramework
import ViewKit
import Combine
import Cocoa
import ModelKit

protocol KeyboardShortcutsFeatureControllerDelegate: AnyObject {
  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didCreateKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow)
  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didUpdateKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow)
  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didDeleteKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow)

}

final class KeyboardShortcutsFeatureController: ActionController {
  weak var delegate: KeyboardShortcutsFeatureControllerDelegate?

  func perform(_ action: KeyboardShortcutList.UIAction) {
    switch action {
    case .create(let shortcut, let offset, let workflow):
      create(shortcut, at: offset, in: workflow)
    case .update(let shortcut, let workflow):
      update(shortcut, in: workflow)
    case .delete(let shortcut, let workflow):
      delete(shortcut, in: workflow)
    case .move(let shortcut, let offset, let workflow):
      move(shortcut, to: offset, in: workflow)
    }
  }

  // MARK: Private methods

  func create(_ keyboardShortcut: KeyboardShortcut,
              at index: Int,
              in workflow: Workflow) {
    var workflow = workflow
    workflow.keyboardShortcuts.add(keyboardShortcut, at: index)
    delegate?.keyboardShortcutFeatureController(self, didCreateKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func update(_ keyboardShortcut: KeyboardShortcut, in workflow: Workflow) {
    var workflow = workflow
    try? workflow.keyboardShortcuts.replace(keyboardShortcut)
    delegate?.keyboardShortcutFeatureController(self, didUpdateKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func delete(_ keyboardShortcut: KeyboardShortcut, in workflow: Workflow) {
    var workflow = workflow
    try? workflow.keyboardShortcuts.remove(keyboardShortcut)
    delegate?.keyboardShortcutFeatureController(self, didDeleteKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func move(_ keyboardShortcut: KeyboardShortcut, to offset: Int, in workflow: Workflow) {
    guard let currentIndex = workflow.keyboardShortcuts.firstIndex(of: keyboardShortcut) else { return }

    let newIndex = currentIndex + offset
    var workflow = workflow
    try? workflow.keyboardShortcuts.move(keyboardShortcut, to: newIndex)
    delegate?.keyboardShortcutFeatureController(self, didUpdateKeyboardShortcut: keyboardShortcut, in: workflow)
  }
}

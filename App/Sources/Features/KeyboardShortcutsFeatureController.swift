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
  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didClearTrigger trigger: Workflow.Trigger,
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
    case .clear(var workflow):
      guard let trigger = workflow.trigger else { return }
      workflow.trigger = nil
      delegate?.keyboardShortcutFeatureController(self, didClearTrigger: trigger, in: workflow)
    }
  }

  // MARK: Private methods

  func create(_ keyboardShortcut: KeyboardShortcut,
              at index: Int,
              in workflow: Workflow) {
    var workflow = workflow

    switch workflow.trigger {
    case var .keyboardShortcuts(shortcuts):
      shortcuts.add(keyboardShortcut, at: index)
      workflow.trigger = .keyboardShortcuts(shortcuts)
    case .none, .application:
      workflow.trigger = .keyboardShortcuts([keyboardShortcut])
    }

    delegate?.keyboardShortcutFeatureController(self, didCreateKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func update(_ keyboardShortcut: KeyboardShortcut, in workflow: Workflow) {
    var workflow = workflow

    switch workflow.trigger {
    case var .keyboardShortcuts(shortcuts):
      try? shortcuts.replace(keyboardShortcut)
      workflow.trigger = .keyboardShortcuts(shortcuts)
    case .none, .application:
      break
    }

    delegate?.keyboardShortcutFeatureController(self, didUpdateKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func delete(_ keyboardShortcut: KeyboardShortcut, in workflow: Workflow) {
    var workflow = workflow

    switch workflow.trigger {
    case var .keyboardShortcuts(shortcuts):
      try? shortcuts.remove(keyboardShortcut)

      if shortcuts.isEmpty {
        workflow.trigger = nil
      } else {
        workflow.trigger = .keyboardShortcuts(shortcuts)
      }
    case .none, .application:
      break
    }

    delegate?.keyboardShortcutFeatureController(self, didDeleteKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func move(_ keyboardShortcut: KeyboardShortcut, to offset: Int, in workflow: Workflow) {
    var workflow = workflow

    switch workflow.trigger {
    case var .keyboardShortcuts(shortcuts):
      guard let currentIndex = shortcuts.firstIndex(of: keyboardShortcut) else { return }
      let newIndex = currentIndex + offset
      try? shortcuts.move(keyboardShortcut, to: newIndex)
      workflow.trigger = .keyboardShortcuts(shortcuts)
    case .none, .application:
      break
    }

    delegate?.keyboardShortcutFeatureController(self, didUpdateKeyboardShortcut: keyboardShortcut, in: workflow)
  }
}

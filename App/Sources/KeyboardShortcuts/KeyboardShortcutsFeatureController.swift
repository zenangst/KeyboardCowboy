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

  let groupsController: GroupsControlling
  private let queue = DispatchQueue(label: "\(bundleIdentifier).KeyboardShortcutsFeatureController",
                                    qos: .userInteractive)

  init(groupsController: GroupsControlling) {
    self.groupsController = groupsController
  }

  func perform(_ action: KeyboardShortcutListView.Action) {
    queue.async { [weak self] in
      guard let self = self else { return }
      switch action {
      case .createKeyboardShortcut(let keyboardShortcut, let index, let workflow):
        self.createKeyboardShortcut(keyboardShortcut, at: index, in: workflow)
      case .updateKeyboardShortcut(let keyboardShortcut, let workflow):
        self.updateKeyboardShortcut(keyboardShortcut, in: workflow)
      case .deleteKeyboardShortcut(let keyboardShortcut, let workflow):
        self.deleteKeyboardShortcut(keyboardShortcut, in: workflow)
      case .moveCommand(let keyboardShortcut, let to, let workflow):
        self.moveKeyboardShortcut(keyboardShortcut, to: to, in: workflow)
      }
    }
  }

  // MARK: Private methods

  func createKeyboardShortcut(_ keyboardShortcut: KeyboardShortcut,
                              at index: Int,
                              in workflow: Workflow) {
    var workflow = workflow
    workflow.keyboardShortcuts.add(keyboardShortcut, at: index)
    delegate?.keyboardShortcutFeatureController(self, didCreateKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func updateKeyboardShortcut(_ keyboardShortcut: KeyboardShortcut, in workflow: Workflow) {
    var workflow = workflow
    try? workflow.keyboardShortcuts.replace(keyboardShortcut)
    delegate?.keyboardShortcutFeatureController(self, didUpdateKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func deleteKeyboardShortcut(_ keyboardShortcut: KeyboardShortcut, in workflow: Workflow) {
    var workflow = workflow
    try? workflow.keyboardShortcuts.remove(keyboardShortcut)
    delegate?.keyboardShortcutFeatureController(self, didDeleteKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func moveKeyboardShortcut(_ keyboardShortcut: KeyboardShortcut, to offset: Int, in workflow: Workflow) {
    guard let currentIndex = workflow.keyboardShortcuts.firstIndex(of: keyboardShortcut) else { return }

    let newIndex = currentIndex + offset
    var workflow = workflow
    try? workflow.keyboardShortcuts.move(keyboardShortcut, to: newIndex)
    delegate?.keyboardShortcutFeatureController(self, didUpdateKeyboardShortcut: keyboardShortcut, in: workflow)
  }
}

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

class KeyboardShortcutsFeatureController: ViewController {
  weak var delegate: KeyboardShortcutsFeatureControllerDelegate?

  @Published var state: [KeyboardShortcut]
  let userSelection: UserSelection
  let groupsController: GroupsControlling
  private var cancellables = [AnyCancellable]()

  init(groupsController: GroupsControlling,
       state: [KeyboardShortcut],
       userSelection: UserSelection) {
    self.groupsController = groupsController
    self._state = Published(initialValue: state)
    self.userSelection = userSelection

    userSelection.$workflow.sink { [weak self] workflow in
      guard let self = self else { return }
      self.state = workflow?.keyboardShortcuts ?? []
    }.store(in: &cancellables)
  }

  func perform(_ action: KeyboardShortcutListView.Action) {
    guard let workflow = userSelection.workflow else { return }

    switch action {
    case .createKeyboardShortcut(let keyboardShortcut, let index):
      createKeyboardShortcut(keyboardShortcut, at: index, in: workflow)
    case .updateKeyboardShortcut(let keyboardShortcut):
      updateKeyboardShortcut(keyboardShortcut, in: workflow)
    case .deleteKeyboardShortcut(let keyboardShortcut):
      deleteKeyboardShortcut(keyboardShortcut, in: workflow)
    case .moveCommand(let from, let to):
      moveKeyboardShortcut(from: from, to: to, in: workflow)
    }
  }

  // MARK: Private methods

  func createKeyboardShortcut(_ keyboardShortcut: KeyboardShortcut,
                              at index: Int,
                              in workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }

    var workflow = context.model
    let keyboardShortcut = KeyboardShortcut(
      id: keyboardShortcut.id, key: keyboardShortcut.key,
      modifiers: keyboardShortcut.modifiers)

    if index < workflow.keyboardShortcuts.count {
      workflow.keyboardShortcuts.insert(keyboardShortcut, at: index)
    } else {
      workflow.keyboardShortcuts.append(keyboardShortcut)
    }

    delegate?.keyboardShortcutFeatureController(self, didCreateKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func updateKeyboardShortcut(_ keyboardShortcut: KeyboardShortcut, in workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }
    guard let previousKeyboardShortcut = context.model.keyboardShortcuts.first(where: { $0.id == keyboardShortcut.id }),
          let index = context.model.keyboardShortcuts.firstIndex(of: previousKeyboardShortcut) else { return }

    var workflow = context.model
    let keyboardShortcut = KeyboardShortcut(
      id: keyboardShortcut.id, key: keyboardShortcut.key,
      modifiers: keyboardShortcut.modifiers)

    workflow.keyboardShortcuts[index] = keyboardShortcut
    delegate?.keyboardShortcutFeatureController(self, didUpdateKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func deleteKeyboardShortcut(_ keyboardShortcut: KeyboardShortcut, in workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }
    guard let keyboardShortcut = context.model.keyboardShortcuts.first(where: { $0.id == keyboardShortcut.id }) else { return }

    let workflow = context.model

    delegate?.keyboardShortcutFeatureController(self, didDeleteKeyboardShortcut: keyboardShortcut, in: workflow)
  }

  func moveKeyboardShortcut(from: Int, to: Int, in workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }

    var workflow = context.model
    let keyboardShortcut = workflow.keyboardShortcuts.remove(at: from)

    if to > workflow.keyboardShortcuts.count {
      workflow.keyboardShortcuts.append(keyboardShortcut)
    } else {
      workflow.keyboardShortcuts.insert(keyboardShortcut, at: to)
    }

    delegate?.keyboardShortcutFeatureController(self, didUpdateKeyboardShortcut: keyboardShortcut, in: workflow)
  }
}

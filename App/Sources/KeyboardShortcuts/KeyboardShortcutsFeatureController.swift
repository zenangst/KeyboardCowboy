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

final class KeyboardShortcutsFeatureController: ViewController {
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
    case .moveCommand(let keyboardShortcut, let to):
      moveKeyboardShortcut(keyboardShortcut, to: to, in: workflow)
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

  func moveKeyboardShortcut(_ keyboardShortcut: KeyboardShortcut, to index: Int, in workflow: Workflow) {
    var workflow = workflow

    var newIndex = index
    if let previousIndex = workflow.keyboardShortcuts.firstIndex(of: keyboardShortcut) {
      if newIndex > previousIndex {
        newIndex -= 1
      }
    }

    try? workflow.keyboardShortcuts.move(keyboardShortcut, to: newIndex)
    delegate?.keyboardShortcutFeatureController(self, didUpdateKeyboardShortcut: keyboardShortcut, in: workflow)
  }
}

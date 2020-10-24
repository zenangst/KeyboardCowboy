import Foundation
import LogicFramework
import ViewKit
import Combine
import ModelKit

protocol WorkflowFeatureControllerDelegate: AnyObject {
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didCreateWorkflow workflow: Workflow,
                                 in group: Group)
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didUpdateWorkflow workflow: Workflow,
                                 in group: Group)
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDeleteWorkflow workflow: Workflow,
                                 in group: Group)
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didMoveWorkflow workflow: Workflow,
                                 in group: Group)
}

final class WorkflowFeatureController: ViewController,
                                 CommandsFeatureControllerDelegate,
                                 KeyboardShortcutsFeatureControllerDelegate {
  weak var delegate: WorkflowFeatureControllerDelegate?
  @Published var state: Workflow?
  let groupsController: GroupsControlling
  let userSelection: UserSelection

  private var cancellables = [AnyCancellable]()

  public init(state: Workflow,
              groupsController: GroupsControlling,
              userSelection: UserSelection) {
    self._state = Published(initialValue: state)
    self.groupsController = groupsController
    self.userSelection = userSelection

    userSelection.$group.sink { [weak self] group in
      guard let group = group else {
        self?.userSelection.workflow = nil
        return
      }

      if !group.workflows.containsElement(self?.userSelection.workflow) {
        self?.userSelection.workflow = group.workflows.first
      }
    }.store(in: &cancellables)

    userSelection.$workflow.sink { [weak self] workflow in
      guard let self = self else { return }
      self.state = workflow
    }.store(in: &cancellables)
  }

  // MARK: ViewController

  func perform(_ action: WorkflowList.Action) {
    switch action {
    case .createWorkflow:
      createWorkflow()
    case .updateWorkflow(let workflow):
      updateWorkflow(workflow)
    case .deleteWorkflow(let workflow):
      deleteWorkflow(workflow)
    case .moveWorkflow(let workflow, let to):
      moveWorkflow(workflow, to: to)
    }
  }

  // MARK: Private methods

  func createWorkflow() {
    guard var group = userSelection.group else { return }
    let workflow = Workflow.empty()
    group.workflows.add(workflow)
    delegate?.workflowFeatureController(self, didCreateWorkflow: workflow, in: group)
  }

  func updateWorkflow(_ workflow: Workflow) {
    guard var group = groupsController.group(for: workflow) else { return }
    try? group.workflows.replace(workflow)
    delegate?.workflowFeatureController(self, didUpdateWorkflow: workflow, in: group)
  }

  func deleteWorkflow(_ workflow: Workflow) {
    guard var group = groupsController.group(for: workflow) else { return }
    try? group.workflows.remove(workflow)
    delegate?.workflowFeatureController(self, didDeleteWorkflow: workflow, in: group)
  }

  private func moveWorkflow(_ workflow: Workflow, to index: Int) {
    guard var group = groupsController.group(for: workflow) else { return }
    try? group.workflows.move(workflow, to: index)
    delegate?.workflowFeatureController(self, didMoveWorkflow: workflow, in: group)
  }

  // MARK: KeyboardShortcutsFeatureControllerDelegate

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didCreateKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow) {
    updateWorkflow(workflow)
  }

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didUpdateKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow) {
    updateWorkflow(workflow)
  }

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didDeleteKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow) {
    updateWorkflow(workflow)
  }

  // MARK: CommandsFeatureControllerDelegate

  func commandsFeatureController(_ controller: CommandsFeatureController,
                                 didCreateCommand command: Command,
                                 in workflow: Workflow) {
    updateWorkflow(workflow)
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didUpdateCommand command: Command,
                                 in workflow: Workflow) {
    updateWorkflow(workflow)
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didDeleteCommand command: Command,
                                 in workflow: Workflow) {
    updateWorkflow(workflow)
  }
}

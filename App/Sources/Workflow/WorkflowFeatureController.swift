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

  private var cancellables = [AnyCancellable]()

  public init(state: Workflow, groupsController: GroupsControlling) {
    self._state = Published(initialValue: state)
    self.groupsController = groupsController
  }

  // MARK: ViewController

  func perform(_ action: WorkflowList.Action) {
    switch action {
    case .createWorkflow(let group):
      createWorkflow(in: group)
    case .updateWorkflow(let workflow, let group):
      updateWorkflow(workflow, in: group)
    case .deleteWorkflow(let workflow, let group):
      deleteWorkflow(workflow, in: group)
    case .moveWorkflow(let workflow, let to, let group):
      moveWorkflow(workflow, to: to, in: group)
    }
  }

  // MARK: Private methods

  func createWorkflow(in group: ModelKit.Group) {
    var group = group
    let workflow = Workflow.empty()
    group.workflows.add(workflow)
    delegate?.workflowFeatureController(self, didCreateWorkflow: workflow, in: group)
  }

  func updateWorkflow(_ workflow: Workflow, in group: ModelKit.Group) {
    var group = group
    try? group.workflows.replace(workflow)
    delegate?.workflowFeatureController(self, didUpdateWorkflow: workflow, in: group)
  }

  func deleteWorkflow(_ workflow: Workflow, in group: ModelKit.Group) {
    var group = group
    try? group.workflows.remove(workflow)
    delegate?.workflowFeatureController(self, didDeleteWorkflow: workflow, in: group)
  }

  private func moveWorkflow(_ workflow: Workflow, to index: Int, in group: ModelKit.Group) {
    var group = group
    try? group.workflows.move(workflow, to: index)
    delegate?.workflowFeatureController(self, didMoveWorkflow: workflow, in: group)
  }

  // MARK: KeyboardShortcutsFeatureControllerDelegate

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didCreateKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didUpdateKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didDeleteKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }

  // MARK: CommandsFeatureControllerDelegate

  func commandsFeatureController(_ controller: CommandsFeatureController,
                                 didCreateCommand command: Command,
                                 in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didUpdateCommand command: Command,
                                 in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didDeleteCommand command: Command,
                                 in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }
}

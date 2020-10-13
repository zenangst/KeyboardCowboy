import Foundation
import LogicFramework
import ViewKit
import Combine
import ModelKit

protocol WorkflowFeatureControllerDelegate: AnyObject {
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didCreateWorkflow workflow: Workflow,
                                 in context: GroupContext)
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didUpdateWorkflow context: WorkflowContext)
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDeleteWorkflow context: WorkflowContext)
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didMoveWorkflow context: WorkflowContext)
}

class WorkflowFeatureController: ViewController,
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
    case .moveWorkflow(let from, let to):
      guard let workflow = state else { return }
      moveWorkflow(from: from, to: to, workflow: workflow)
    }
  }

  // MARK: Private methods

  func createWorkflow() {
    guard let groupId = userSelection.group?.id,
          let context = groupsController.groupContext(withIdentifier: groupId)
    else { return }

    delegate?.workflowFeatureController(self, didCreateWorkflow: Workflow.empty(),
                                        in: context)
  }

  func updateWorkflow(_ workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }

    let newContext = WorkflowContext(index: context.index,
                                     groupContext: context.groupContext,
                                     model: workflow)

    delegate?.workflowFeatureController(self, didUpdateWorkflow: newContext)
  }

  func deleteWorkflow(_ workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }
    delegate?.workflowFeatureController(self, didDeleteWorkflow: context)
  }

  private func moveWorkflow(from: Int, to: Int, workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }

    var group = context.groupContext.model
    let workflow = group.workflows.remove(at: from)

    if to > group.workflows.count {
      group.workflows.append(workflow)
    } else {
      group.workflows.insert(workflow, at: to)
    }

    let groupContext = GroupContext(index: context.groupContext.index, model: group)
    let workflowContext = WorkflowContext(index: context.index,
                                          groupContext: groupContext,
                                          model: workflow)

    delegate?.workflowFeatureController(self, didMoveWorkflow: workflowContext)
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
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }
    guard let index = context.model.keyboardShortcuts.firstIndex(of: keyboardShortcut) else { return }

    var workflow = context.model
    workflow.keyboardShortcuts.remove(at: index)
    updateWorkflow(workflow)
  }

  // MARK: CommandsFeatureControllerDelegate

  func commandsFeatureController(_ controller: CommandsFeatureController, didCreateCommand command: Command,
                                 in workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }

    let newContext = WorkflowContext(index: context.index,
                                     groupContext: context.groupContext,
                                     model: workflow)

    delegate?.workflowFeatureController(self, didUpdateWorkflow: newContext)
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didUpdateCommand command: Command,
                                 in workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }

    let newContext = WorkflowContext(index: context.index, groupContext: context.groupContext, model: workflow)

    delegate?.workflowFeatureController(self, didUpdateWorkflow: newContext)
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didDeleteCommand command: Command,
                                 in workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }
    guard let index = context.model.commands.firstIndex(of: command) else { return }

    var workflow = context.model
    workflow.commands.remove(at: index)

    let newContext = WorkflowContext(index: context.index, groupContext: context.groupContext, model: workflow)
    delegate?.workflowFeatureController(self, didUpdateWorkflow: newContext)
  }
}

import Foundation
import LogicFramework
import ViewKit
import Combine

protocol WorkflowFeatureControllerDelegate: AnyObject {
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didCreateWorkflow workflow: Workflow,
                                 in context: GroupContext)
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didUpdateWorkflow context: WorkflowContext)
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDeleteWorkflow context: WorkflowContext)
}

class WorkflowFeatureController: ViewController, CommandsFeatureControllerDelegate {
  weak var delegate: WorkflowFeatureControllerDelegate?
  @Published var state: WorkflowViewModel?
  let groupsController: GroupsControlling
  let userSelection: UserSelection

  private var cancellables = [AnyCancellable]()

  public init(state: WorkflowViewModel,
              groupsController: GroupsControlling,
              userSelection: UserSelection) {
    self._state = Published(initialValue: state)
    self.groupsController = groupsController
    self.userSelection = userSelection

    userSelection.$workflow.sink { workflow in
      self.state = workflow
    }.store(in: &cancellables)
  }

  // MARK: ViewController

  func perform(_ action: WorkflowList.Action) {
    switch action {
    case .createWorkflow:
      createWorkflow()
    case .updateWorkflow(let viewModel):
      updateWorkflow(viewModel)
    case .deleteWorkflow(let viewModel):
      deleteWorkflow(viewModel)
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

  func updateWorkflow(_ viewModel: WorkflowViewModel) {
    guard let context = groupsController.workflowContext(workflowId: viewModel.id) else { return }

    var workflow = context.model
    workflow.name = viewModel.name

    let newContext = WorkflowContext(index: context.index,
                                     groupContext: context.groupContext,
                                     model: workflow)

    delegate?.workflowFeatureController(self, didUpdateWorkflow: newContext)
  }

  func deleteWorkflow(_ viewModel: WorkflowViewModel) {
    guard let context = groupsController.workflowContext(workflowId: viewModel.id) else { return }
    delegate?.workflowFeatureController(self, didDeleteWorkflow: context)
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

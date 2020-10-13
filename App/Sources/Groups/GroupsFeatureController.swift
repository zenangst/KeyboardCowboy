import Foundation
import LogicFramework
import ViewKit
import ModelKit

protocol GroupsFeatureControllerDelegate: AnyObject {
  func groupsFeatureController(_ controller: GroupsFeatureController, didReloadGroups groups: [Group])
}

class GroupsFeatureController: ViewController, WorkflowFeatureControllerDelegate {
  weak var delegate: GroupsFeatureControllerDelegate?

  @Published var state = [Group]()
  var applications = [Application]()
  let groupsController: GroupsControlling
  let userSelection: UserSelection

  init(groupsController: GroupsControlling,
       userSelection: UserSelection) {
    self.groupsController = groupsController
    self.userSelection = userSelection
    self.state = groupsController.groups
    self.userSelection.group = self.state.first
    self.userSelection.workflow = self.state.first?.workflows.first
  }

  // MARK: ViewController

  func perform(_ action: GroupList.Action) {
    switch action {
    case .createGroup:
      newGroup()
    case .deleteGroup(let group):
      delete(group)
    case .updateGroup(let group):
      save(group)
    case .dropFile(let url):
      processUrl(url)
    case .moveGroup(let from, let to):
      move(from: from, to: to)
    }
  }

  // MARK: Private methods

  private func reload(_ groups: [Group], completion: (([ModelKit.Group]) -> Void)? = nil) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.groupsController.reloadGroups(groups)
      self.delegate?.groupsFeatureController(self, didReloadGroups: groups)
      completion?(groups)
      self.state = groups
    }
  }

  private func newGroup() {
    let newGroup = Group.empty()
    var groups = groupsController.groups
    groups.append(newGroup)
    reload(groups)
  }

  private func processUrl(_ url: URL) {
    guard let application = applications.first(where: { $0.path == url.path }) else {
      return
    }

    var groups = groupsController.groups
    let group = Group.droppedApplication(application)
    groups.append(group)
    reload(groups)
  }

  private func move(from: Int, to: Int) {
    var groups = groupsController.groups
    let group = groups.remove(at: from)

    if to > groups.count {
      groups.append(group)
    } else {
      groups.insert(group, at: to)
    }
    reload(groups)
  }

  private func save(_ group: ModelKit.Group) {
    guard let ctx = groupsController.groupContext(withIdentifier: group.id) else {
      return
    }

    var groups = groupsController.groups
    groups[ctx.index] = group
    reload(groups)
    userSelection.group = group
  }

  private func delete(_ group: ModelKit.Group) {
    guard let ctx = groupsController.groupContext(withIdentifier: group.id) else {
      return
    }

    var groups = groupsController.groups
    groups.remove(at: ctx.index)
    reload(groups)
  }

  // MARK: WorkflowFeatureControllerDelegate

  func workflowFeatureController(_ controller: WorkflowFeatureController, didCreateWorkflow workflow: Workflow,
                                 in context: GroupContext) {
    var groups = self.groupsController.groups
    var group = context.model
    var workflows = group.workflows

    workflows.append(workflow)
    group.workflows = workflows
    groups[context.index] = group

    reload(groups) { [weak self] groups in
      self?.userSelection.group = groups.first
      self?.userSelection.workflow = groups.flatMap({ $0.workflows }).first(where: { $0.id == workflow.id })
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController, didUpdateWorkflow context: WorkflowContext) {
    var groups = self.groupsController.groups
    var group = context.groupContext.model
    var workflows = group.workflows

    workflows[context.index] = context.model
    group.workflows = workflows
    groups[context.groupContext.index] = group

    reload(groups) { [weak self] groups in
      self?.userSelection.group = groups.first(where: { $0.id == context.groupContext.model.id })
      self?.userSelection.workflow = groups.flatMap({ $0.workflows }).first(where: { $0.id == context.model.id })
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController, didDeleteWorkflow context: WorkflowContext) {
    var groups = self.groupsController.groups
    var group = context.groupContext.model
    var workflows = group.workflows

    workflows.remove(at: context.index)
    group.workflows = workflows
    groups[context.groupContext.index] = group

    reload(groups) { [weak self] groups in
      self?.userSelection.group = groups.first(where: { $0.id == context.groupContext.model.id })
      self?.userSelection.workflow = groups.flatMap({ $0.workflows }).first(where: { $0.id == context.model.id })
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController, didMoveWorkflow context: WorkflowContext) {
    var groups = self.groupsController.groups
    var group = context.groupContext.model
    let workflows = group.workflows

    group.workflows = workflows
    groups[context.groupContext.index] = group

    reload(groups) { [weak self] groups in
      self?.userSelection.group = groups.first(where: { $0.id == context.groupContext.model.id })
      self?.userSelection.workflow = groups.flatMap({ $0.workflows }).first(where: { $0.id == context.model.id })
    }
  }
}

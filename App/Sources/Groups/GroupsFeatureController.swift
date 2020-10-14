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
    let group = Group.empty()
    var groups = groupsController.groups
    groups.append(group)
    reload(groups) { _ in
      self.userSelection.group = group
      self.userSelection.workflow = nil
    }
  }

  private func processUrl(_ url: URL) {
    guard let application = applications.first(where: { $0.path == url.path }) else {
      return
    }

    var groups = groupsController.groups
    let group = Group.droppedApplication(application)
    groups.append(group)
    reload(groups) { _ in
      self.userSelection.group = group
      self.userSelection.workflow = nil
    }
  }

  private func move(from: Int, to: Int) {
    var groups = groupsController.groups
    let group = groups.remove(at: from)

    if to > groups.count {
      groups.append(group)
    } else {
      groups.insert(group, at: to)
    }
    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = nil
    }
  }

  private func save(_ group: ModelKit.Group) {
    guard let ctx = groupsController.groupContext(withIdentifier: group.id) else {
      return
    }

    var groups = groupsController.groups
    groups[ctx.index] = group
    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
    }
  }

  private func delete(_ group: ModelKit.Group) {
    guard let ctx = groupsController.groupContext(withIdentifier: group.id) else {
      return
    }

    var groups = groupsController.groups
    groups.remove(at: ctx.index)

    var selectedGroup: Group?
    if !groups.isEmpty {
      let index = max(groups.count - 1, 0)
      selectedGroup = groups[index]
    }

    reload(groups) { [weak self] _ in
      self?.userSelection.group = selectedGroup
      self?.userSelection.workflow = nil
    }
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

    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = workflow
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController, didUpdateWorkflow context: WorkflowContext) {
    var groups = self.groupsController.groups
    var group = context.groupContext.model
    var workflows = group.workflows

    workflows[context.index] = context.model
    group.workflows = workflows
    groups[context.groupContext.index] = group

    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = context.model
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController, didDeleteWorkflow context: WorkflowContext) {
    var groups = self.groupsController.groups
    var group = context.groupContext.model
    var workflows = group.workflows

    workflows.remove(at: context.index)
    group.workflows = workflows
    groups[context.groupContext.index] = group

    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = group.workflows.first
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController, didMoveWorkflow context: WorkflowContext) {
    var groups = self.groupsController.groups
    var group = context.groupContext.model
    let workflows = group.workflows

    group.workflows = workflows
    groups[context.groupContext.index] = group

    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = context.model
    }
  }
}

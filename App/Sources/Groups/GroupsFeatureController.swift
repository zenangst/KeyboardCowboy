import Foundation
import LogicFramework
import ViewKit
import ModelKit

protocol GroupsFeatureControllerDelegate: AnyObject {
  func groupsFeatureController(_ controller: GroupsFeatureController, didReloadGroups groups: [Group])
}

final class GroupsFeatureController: ViewController, WorkflowFeatureControllerDelegate {
  weak var delegate: GroupsFeatureControllerDelegate?

  @Published var state = [Group]()
  var applications = [Application]()
  let groupsController: GroupsControlling
  let userSelection: UserSelection

  init(groupsController: GroupsControlling,
       userSelection: UserSelection,
       applications: [Application]) {
    self.applications = applications
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
    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = nil
    }
  }

  private func processUrl(_ url: URL) {
    guard let application = applications.first(where: { $0.path == url.path }) else {
      return
    }

    var groups = groupsController.groups
    let group = Group.droppedApplication(application)
    groups.append(group)
    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = nil
    }
  }

  private func move(from: Int, to: Int) {
    var groups = groupsController.groups
    let group = groups.remove(at: from)

    var newIndex = to
    if to > from {
      newIndex -= 1
    }

    if to > groups.count {
      groups.append(group)
    } else {
      groups.insert(group, at: max(newIndex, 0))
    }
    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = nil
    }
  }

  private func save(_ group: ModelKit.Group) {
    var groups = groupsController.groups
    try? groups.replace(group)
    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = nil
    }
  }

  private func delete(_ group: ModelKit.Group) {
    var groups = groupsController.groups
    try? groups.remove(group)

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
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)

    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = workflow
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didUpdateWorkflow workflow: Workflow,
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = workflow
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDeleteWorkflow workflow: Workflow,
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)

    var selectedWorkflow: Workflow?
    if !group.workflows.isEmpty {
      let index = max(group.workflows.count - 1, 0)
      selectedWorkflow = group.workflows[index]
    }

    reload(groups) { [weak self] groups in
      self?.userSelection.group = groups.first
      self?.userSelection.workflow = selectedWorkflow
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didMoveWorkflow workflow: Workflow,
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups) { [weak self] _ in
      self?.userSelection.group = group
      self?.userSelection.workflow = workflow
    }
  }
}

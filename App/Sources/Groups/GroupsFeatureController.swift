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

  init(groupsController: GroupsControlling, applications: [Application],
       userSelection: UserSelection) {
    self.applications = applications
    self.groupsController = groupsController
    self.state = groupsController.groups
    self.userSelection = userSelection
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

  private func reload(_ groups: [Group]) {
    self.groupsController.reloadGroups(groups)
    self.delegate?.groupsFeatureController(self, didReloadGroups: groups)
    self.state = groups
  }

  private func newGroup() {
    let group = Group.empty()
    var groups = groupsController.groups
    groups.append(group)
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

    var newIndex = to
    if to > from {
      newIndex -= 1
    }

    if to > groups.count {
      groups.append(group)
    } else {
      groups.insert(group, at: max(newIndex, 0))
    }
    reload(groups)
  }

  private func save(_ group: ModelKit.Group) {
    var groups = groupsController.groups
    try? groups.replace(group)
    userSelection.group = group
    reload(groups)
  }

  private func delete(_ group: ModelKit.Group) {
    var groups = groupsController.groups
    try? groups.remove(group)
    reload(groups)
  }

  // MARK: WorkflowFeatureControllerDelegate

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didCreateWorkflow workflow: Workflow,
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups)
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didUpdateWorkflow workflow: Workflow,
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    userSelection.group = group
    userSelection.workflow = workflow
    reload(groups)
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDeleteWorkflow workflow: Workflow,
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups)
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didMoveWorkflow workflow: Workflow,
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups)
    userSelection.group = group
    userSelection.workflow = workflow
  }
}

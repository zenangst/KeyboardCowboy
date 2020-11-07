import Combine
import Foundation
import LogicFramework
import ViewKit
import ModelKit

final class GroupsFeatureController: ViewController, WorkflowFeatureControllerDelegate {
  var subject = PassthroughSubject<[Group], Never>()
  var state = [Group]()
  var applications = [Application]()
  let groupsController: GroupsControlling
  let userSelection: UserSelection
  let queue = DispatchQueue(label: "\(bundleIdentifier).GroupsFeatureController", qos: .userInteractive)

  init(groupsController: GroupsControlling, applications: [Application],
       userSelection: UserSelection) {
    self.applications = applications
    self.groupsController = groupsController
    self.state = groupsController.groups
    self.userSelection = userSelection
  }

  // MARK: ViewController

  func perform(_ action: GroupList.Action) {
    queue.async { [weak self] in
      guard let self = self else { return }
      switch action {
      case .createGroup:
        self.newGroup()
      case .deleteGroup(let group):
        self.delete(group)
      case .updateGroup(let group):
        self.save(group)
      case .dropFile(let url):
        self.processUrl(url)
      case .moveGroup(let from, let to):
        self.move(from: from, to: to)
      }
    }
  }

  // MARK: Private methods

  private func reload(_ groups: [Group], then handler: ((UserSelection) -> Void)? = nil) {
    groupsController.reloadGroups(groups)
    subject.send(groups)

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.state = groups
      handler?(self.userSelection)
    }
  }

  private func newGroup() {
    let group = Group.empty()
    var groups = groupsController.groups
    groups.append(group)
    reload(groups) { userSelection in
      userSelection.group = group
      userSelection.workflow = nil
    }
  }

  private func processUrl(_ url: URL) {
    guard let application = applications.first(where: { $0.path == url.path }) else {
      return
    }

    var groups = groupsController.groups
    let group = Group.droppedApplication(application)
    groups.append(group)
    reload(groups) { userSelection in
      userSelection.group = group
      userSelection.workflow = nil
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
    reload(groups) { userSelection in
      userSelection.group = group
    }
  }

  private func save(_ group: ModelKit.Group) {
    var groups = groupsController.groups
    try? groups.replace(group)
    reload(groups) { userSelection in
      userSelection.group = group
    }
  }

  private func delete(_ group: ModelKit.Group) {
    var groups = groupsController.groups
    try? groups.remove(group)
    reload(groups) { userSelection in
      userSelection.group = groups.first
      userSelection.workflow = groups.first?.workflows.first
    }
  }

  // MARK: WorkflowFeatureControllerDelegate

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didCreateWorkflow workflow: Workflow,
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups) {
      $0.group = group
      $0.workflow = workflow
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didUpdateWorkflow workflow: Workflow,
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups, then: {
      $0.group = group
      $0.workflow = workflow
    })
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDeleteWorkflow workflow: Workflow,
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups) {
      $0.group = group
      $0.workflow = group.workflows.first
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didMoveWorkflow workflow: Workflow,
                                 in group: Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups, then: { userSelection in
      userSelection.group = group
      userSelection.workflow = workflow
    })
  }
}

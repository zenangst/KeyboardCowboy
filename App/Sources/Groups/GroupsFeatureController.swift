import Combine
import Foundation
import LogicFramework
import ViewKit
import ModelKit

final class GroupsFeatureController: ViewController,
                                     WorkflowFeatureControllerDelegate {
  var subject = PassthroughSubject<[ModelKit.Group], Never>()
  var state = [ModelKit.Group]()
  var applications = [Application]()
  let groupsController: GroupsControlling
  let userSelection: UserSelection

  init(groupsController: GroupsControlling, applications: [Application],
       userSelection: UserSelection) {
    userSelection.group = groupsController.groups.first
    userSelection.workflow = groupsController.groups.first?.workflows.first

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
    case .dropFile(let urls):
      for url in urls {
        processUrl(url)
      }
    case .moveGroup(let from, let to):
      move(from: from, to: to)
    }
  }

  // MARK: Private methods

  private func reload(_ groups: [ModelKit.Group], then handler: ((UserSelection) -> Void)? = nil) {
    groupsController.reloadGroups(groups)
    subject.send(groups)
    self.state = groups
    handler?(self.userSelection)
  }

  private func newGroup() {
    let group = ModelKit.Group.empty()
    var groups = groupsController.groups
    groups.append(group)

    reload(groups) { userSelection in
      userSelection.group = group
      userSelection.workflow = group.workflows.first
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
                                 in group: ModelKit.Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups) { userSelection in
      userSelection.group = group
      userSelection.workflow = workflow
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didUpdateWorkflow workflow: Workflow,
                                 in group: ModelKit.Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups) { userSelection in
      userSelection.group = group
      userSelection.workflow = workflow
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDeleteWorkflow workflow: Workflow,
                                 in group: ModelKit.Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups) { userSelection in
      userSelection.group = group
      userSelection.workflow = group.workflows.first
    }
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didMoveWorkflow workflow: Workflow,
                                 in group: ModelKit.Group) {
    var groups = self.groupsController.groups
    try? groups.replace(group)
    reload(groups, then: { userSelection in
      userSelection.group = group
      userSelection.workflow = workflow
    })
  }
}

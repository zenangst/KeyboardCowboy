import Combine
import Foundation
import LogicFramework
import ViewKit
import ModelKit
import SwiftUI

enum GroupsFeatureError: Error {
  case unableToFindGroup
}

final class GroupsFeatureController: ActionController,
                                     WorkflowFeatureControllerDelegate {
  @AppStorage("groupSelection") var groupSelection: String?
  @AppStorage("workflowSelection") var workflowSelection: String?
  var subject = PassthroughSubject<[ModelKit.Group], Never>()
  var applications = [Application]()
  let groupsController: GroupsControlling

  init(groupsController: GroupsControlling, applications: [Application]) {
    self.applications = applications
    self.groupsController = groupsController
  }

  // MARK: ViewController

  func perform(_ action: GroupList.Action) {
    switch action {
    case .createGroup:
      create()
    case .deleteGroup(let group):
      delete(group)
    case .updateGroup(let group):
      update(group)
    case .dropFile(let urls):
      for url in urls {
        processUrl(url)
      }
    case .moveGroup(let from, let to):
      move(from: from, to: to)
    }
  }

  // MARK: Private methods

  private func reload(_ groups: [ModelKit.Group]) {
    groupsController.reloadGroups(groups)
    subject.send(groups)
  }

  private func create() {
    let group = ModelKit.Group.empty()
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

  private func update(_ group: ModelKit.Group) {
    var groups = groupsController.groups
    try? groups.replace(group)
    reload(groups)
  }

  private func delete(_ group: ModelKit.Group) {
    var groups = groupsController.groups
    try? groups.remove(group)
    reload(groups)
  }

  private func findGroup(for workflow: Workflow) throws -> ModelKit.Group {
    guard let group = groupsController.groups.first(where: {
      $0.workflows.first(where: { $0.id == workflow.id }) != nil
    }) else {
      throw GroupsFeatureError.unableToFindGroup
    }
    return group
  }

  // MARK: WorkflowFeatureControllerDelegate

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didCreateWorkflow workflow: Workflow,
                                 groupId: String) throws {
    guard var group = groupsController.groups.first(where: { $0.id == groupId }) else {
      return
    }
    var groups = self.groupsController.groups
    group.workflows.add(workflow)
    try groups.replace(group)
    reload(groups)
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didUpdateWorkflow workflow: Workflow) throws {
    workflowSelection = workflow.id

    var group = try findGroup(for: workflow)
    var groups = self.groupsController.groups
    try group.workflows.replace(workflow)
    try groups.replace(group)
    reload(groups)
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDeleteWorkflow workflow: Workflow) throws {
    var group = try findGroup(for: workflow)
    var groups = self.groupsController.groups
    try group.workflows.remove(workflow)
    try groups.replace(group)
    reload(groups)
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didMoveWorkflow workflow: Workflow,
                                 to offset: Int) throws {
    var group = try findGroup(for: workflow)
    var groups = self.groupsController.groups
    try group.workflows.move(workflow, to: offset)
    try groups.replace(group)
    reload(groups)
  }

  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDropWorkflow workflow: Workflow,
                                 groupId: String) throws {
    guard var group = groupsController.groups.first(where: { $0.id == groupId }) else {
      return
    }
    var groups = self.groupsController.groups
    group.workflows.add(workflow)
    try groups.replace(group)
    reload(groups)
  }
}

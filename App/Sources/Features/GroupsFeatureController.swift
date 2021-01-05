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
                                     WorkflowsFeatureControllerDelegate {
  @AppStorage("groupSelection") var groupSelection: String?
  @AppStorage("workflowSelection") var workflowSelection: String?
  @AppStorage("workflowSelections") var workflowSelections: String?
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

    if let offset = groups.firstIndex(of: group) {
      try? groups.remove(group)

      // Select the "above" group when deleting the currently selected.
      // In addition, select the first workflow in the group.
      let nextIndex = max(0, offset - 1)
      if groups.count > 0 {
        let newSelectedGroup = groups[nextIndex]
        groupSelection = newSelectedGroup.id
        workflowSelection = newSelectedGroup.workflows.first?.id
      }
    }

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

  func workflowsFeatureController(_ controller: WorkflowsFeatureController,
                                  didCreateWorkflow workflow: Workflow,
                                  groupId: String) throws {
    guard var group = groupsController.groups.first(where: { $0.id == groupId }) else {
      return
    }
    var groups = self.groupsController.groups
    group.workflows.add(workflow)
    try groups.replace(group)
    reload(groups)
    workflowSelection = group.workflows.last?.id
    workflowSelections = workflowSelection
  }

  func workflowsFeatureController(_ controller: WorkflowsFeatureController,
                                  didUpdateWorkflow workflow: Workflow) throws {
    workflowSelection = workflow.id

    var group = try findGroup(for: workflow)
    var groups = self.groupsController.groups
    try group.workflows.replace(workflow)
    try groups.replace(group)
    reload(groups)
  }

  func workflowsFeatureController(_ controller: WorkflowsFeatureController,
                                  didDeleteWorkflow workflow: Workflow) throws {
    var group = try findGroup(for: workflow)
    var groups = self.groupsController.groups
    try group.workflows.remove(workflow)
    try groups.replace(group)
    reload(groups)

    if var array = workflowSelection?.split(separator: ",").compactMap(String.init),
       let index = array.firstIndex(of: workflow.id) {
      array.remove(at: index)
      self.workflowSelections = array.joined(separator: ",")
    }
  }

  func workflowsFeatureController(_ controller: WorkflowsFeatureController,
                                  didMoveWorkflow workflow: Workflow,
                                  to offset: Int) throws {
    var group = try findGroup(for: workflow)
    var groups = self.groupsController.groups
    try group.workflows.move(workflow, to: offset)
    try groups.replace(group)
    reload(groups)
  }

  func workflowsFeatureController(_ controller: WorkflowsFeatureController,
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

  func workflowsFeatureController(_ controller: WorkflowsFeatureController, didTransferWorkflowIds workflowIds: Set<String>, toGroup group: ModelKit.Group) throws {
    var newGroup = group
    guard let groupId = groupSelection,
      var currentGroup = groupsController.groups.first(where: { $0.id == groupId }) else {
      return
    }

    var groups = self.groupsController.groups

    for id in workflowIds {
      guard let workflow = currentGroup.workflows.first(where: { $0.id == id }) else {
        continue
      }
      try currentGroup.workflows.remove(workflow)
      newGroup.workflows.add(workflow)

      try groups.replace(currentGroup)
      try groups.replace(newGroup)
    }

    reload(groups)
  }
}

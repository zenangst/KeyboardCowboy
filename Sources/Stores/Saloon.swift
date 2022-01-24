import Foundation
import SwiftUI

let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil

@MainActor
final class Saloon: ObservableObject {
  @Published var preferences: AppPreferences

  private let storage: Storage

  private(set) var groupStore = WorkflowGroupStore()
  @Published var selectedGroups = [WorkflowGroup]()
  @Published var selectedWorkflows = [Workflow]()

  @AppStorage("selectedGroupIds") private var initialSelectedGroups = [String]()
  @AppStorage("selectedWorkflowIds") private var initialSelectedWorkflows = [String]()

  init(_ preferences: AppPreferences = .designTime()) {
    self.preferences = preferences
    self.storage = Storage(preferences.storageConfiguration)
    Task {
      if preferences.hideAppOnLaunch {
        NSApp.hide(self)
      }
      self.groupStore.groups = try await storage.load()
      initialSelection()
    }
  }

  func receive(_ newWorkflows: [Workflow]) {
    var groups = [WorkflowGroup]()
    for newWorkflow in newWorkflows {
      guard let group = groupStore.groups.first(where: { group in
        let workflowIds = group.workflows.compactMap({ $0.id })
        return workflowIds.contains(newWorkflow.id)
      })
      else { continue }

      groups.append(group)

      guard let groupIndex = groupStore.groups.firstIndex(of: group)
      else { continue }

      guard let workflowIndex = group.workflows.firstIndex(where: { $0.id == newWorkflow.id })
      else { continue }

      let oldWorkflow = groupStore.groups[groupIndex].workflows[workflowIndex]
      if oldWorkflow == newWorkflow {
        continue
      }

      groupStore.groups[groupIndex].workflows[workflowIndex] = newWorkflow
    }

    initialSelection()

    try? storage.save(groupStore.groups)
  }

  /// Configure the initial selection on start
  private func initialSelection() {
    selectedGroups = groupStore.groups.filter({
      initialSelectedGroups.contains($0.id)
    })
    selectedWorkflows = selectedGroups
        .flatMap({ $0.workflows })
        .filter({
          initialSelectedWorkflows.contains($0.id)
        })
  }
}

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
      self.storage.subscribe(to: self.groupStore.$groups)
      initialSelection()
    }
  }

  func receive(_ newWorkflows: [Workflow]) {
    groupStore.receive(newWorkflows)
    initialSelection()
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

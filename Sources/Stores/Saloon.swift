import Foundation
import SwiftUI

let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil

@MainActor
final class Saloon: ObservableObject {
  private let storage: Storage
  private(set) var groupStore = WorkflowGroupStore()
  @Published var selectedGroups = Set<WorkflowGroup>()
  @Published var selectedWorkflows = Set<Workflow>()

  @AppStorage("selectedGroupIds") private var initialSelectedGroups = [String]()
  @AppStorage("selectedWorkflowIds") private var initialSelectedWorkflows = [String]()

  init() {
    self.storage = Storage(path: "~/Developer/KC", fileName: "dummyData.json")
    Task {
      self.groupStore.groups = try await storage.load()
      initialSelection()
    }
  }

  /// Configure the initial selection on start
  private func initialSelection() {
    selectedGroups = Set<WorkflowGroup>(groupStore.groups.filter({
      initialSelectedGroups.contains($0.id)
    }))
    selectedWorkflows = Set<Workflow>(
      selectedGroups
        .flatMap({ $0.workflows })
        .filter({
          initialSelectedWorkflows.contains($0.id)
        }))
  }
}

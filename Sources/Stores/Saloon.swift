import Combine
import Foundation
import SwiftUI

let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil

@MainActor
final class Saloon: ObservableObject {
  @Published var preferences: AppPreferences

  private let storage: Storage
  private var subscriptions = [AnyCancellable]()

  private(set) var applicationStore = ApplicationStore()
  private(set) var configurationStore: ConfigurationStore
  private(set) var groupStore: GroupStore
  @Published var selectedWorkflows = [Workflow]()
  @Published var selectedWorkflowsCopy = [Workflow]()

  @AppStorage("selectedGroupIds") var groupIds = Set<String>()
  @AppStorage("selectedWorkflowIds") var workflowIds = [String]()
  @AppStorage("selectedConfiguration") private(set) var configurationId: String = ""

  init(_ preferences: AppPreferences = .designTime()) {
    self.groupStore = GroupStore()
    self.configurationStore = ConfigurationStore()
    self.preferences = preferences
    self.storage = Storage(preferences.storageConfiguration)

    Task {
      if preferences.hideAppOnLaunch { NSApp.hide(self) }
      let configurations: [Configuration]
      configurations = try await load()
      configurationStore.updateConfigurations(configurations)
      use(configurationStore.selectedConfiguration)
      storage.subscribe(to: configurationStore.$configurations)
      subscribe(to: groupStore.$groups)
    }
  }

  func load() async throws -> [Configuration] {
    let configurations: [Configuration]
    do {
      configurations = try await storage.load()
    } catch {
      configurations = try await migrateIfNeeded()
    }
    return configurations
  }

  func migrateIfNeeded() async throws -> [Configuration] {
    let groups: [WorkflowGroup] = try await storage.load()
    let configuration = Configuration(name: "Default configuration", groups: groups)
    return [configuration]
  }

  func use(_ configuration: Configuration) {
    configurationId = configuration.id
    // Select first group if the selection is empty
    if groupIds.isEmpty, let group = configuration.groups.first {
      groupIds = [group.id]
      groupStore.selectedGroups = [group]
    } else {
      let groups = configuration.groups.filter({ groupIds.contains($0.id) })
      groupIds = Set<String>(groups.compactMap { $0.id })
      groupStore.selectedGroups = groups
    }

    groupStore.groups = configuration.groups

    if workflowIds.isEmpty,
       let group = groupStore.groups.first,
       let workflow = group.workflows.first {
      workflowIds = [workflow.id]
      selectedWorkflows = [workflow]
    } else if let group = groupStore.groups.first {
      let workflows = group.workflows.filter { workflowIds.contains($0.id) }
      workflowIds = workflows.compactMap { $0.id }
      selectedWorkflows = workflows
    }
  }

  func selectGroups(_ ids: Set<String>) {
    groupIds = ids
    groupStore.selectedGroups = configurationStore.selectedConfiguration.groups
      .filter { ids.contains($0.id) }

    if let workflow = groupStore.selectedGroups.first?.workflows.first {
      workflowIds = [workflow.id]
      selectedWorkflows = [workflow]
    }
  }

  func selectWorkflows(_ ids: Set<String>) {
    workflowIds = Array(ids)
    selectedWorkflows = groupStore.selectedGroups
      .flatMap {
        $0.workflows.filter { ids.contains($0.id) }
      }
    selectedWorkflowsCopy = selectedWorkflows
  }

  func updateWorkflows(_ newWorkflows: [Workflow]) {
    if selectedWorkflowsCopy == newWorkflows { return }

    Task(priority: .high) {
      let newGroups = await groupStore.receive(newWorkflows)
      var newConfiguration = configurationStore.selectedConfiguration
      newConfiguration.groups = newGroups

      configurationStore.update(newConfiguration)

      selectGroups(groupIds)
      let workflowIds = Set<String>(newWorkflows.compactMap({ $0.id }))
      selectWorkflows(workflowIds)
    }
  }

  // MARK: Private methods

  private func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    publisher
      .dropFirst()
      .removeDuplicates()
      .sink { [weak self, configurationStore] groups in
        var newConfiguration = configurationStore.selectedConfiguration

        if newConfiguration.groups != groups {
          newConfiguration.groups = groups
          configurationStore.update(newConfiguration)
        }

        configurationStore.select(newConfiguration)
        self?.use(newConfiguration)
    }.store(in: &subscriptions)
  }

  private func generatePerformanceData() {
      for x in 0..<100 {
        var group = WorkflowGroup(name: "Group \(x + 1)")
        for y in 0..<300 {
          let workflow = Workflow(name: "Workflow \(y + 1)")
          group.workflows.append(workflow)
        }
        groupStore.add(group)
      }
  }
}

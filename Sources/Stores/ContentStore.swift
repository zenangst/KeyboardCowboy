import Combine
import Foundation
import SwiftUI

@MainActor
final class ContentStore: ObservableObject {
  @Published private(set) var preferences: AppPreferences

  var undoManager: UndoManager?

  private let storage: Storage
  private var subscriptions = [AnyCancellable]()

  private(set) var applicationStore = ApplicationStore()
  private(set) var configurationStore: ConfigurationStore
  private(set) var groupStore: GroupStore
  private(set) var recorderStore = KeyShortcutRecorderStore()
  private(set) var shortcutStore: ShortcutStore
  
  @Published var selectedWorkflows = [Workflow]()
  @Published var selectedWorkflowsCopy = [Workflow]()

  @AppStorage("selectedGroupIds") private var groupIds = Set<String>()
  @AppStorage("selectedWorkflowIds") private var workflowIds = Set<String>()
  @AppStorage("selectedConfiguration") private var configurationId: String = ""

  init(_ preferences: AppPreferences) {
    self.shortcutStore = ShortcutStore()
    self.groupStore = GroupStore()
    self.configurationStore = ConfigurationStore()
    self.preferences = preferences
    self.storage = Storage(preferences.storageConfiguration)

    if preferences.hideAppOnLaunch { NSApplication.shared.hide(self) }

    Task {
      shortcutStore.index()
      let configurations: [KeyboardCowboyConfiguration]
      configurations = try await load()
      configurationStore.updateConfigurations(configurations)
      use(configurationStore.selectedConfiguration)
      storage.subscribe(to: configurationStore.$configurations)
      subscribe(to: groupStore.$groups)
    }
  }

  func load() async throws -> [KeyboardCowboyConfiguration] {
    let configurations: [KeyboardCowboyConfiguration]
    do {
      configurations = try await storage.load()
    } catch {
      configurations = try await migrateIfNeeded()
    }
    return configurations
  }

  func migrateIfNeeded() async throws -> [KeyboardCowboyConfiguration] {
    let groups: [WorkflowGroup] = try await storage.load()
    let configuration = KeyboardCowboyConfiguration(name: "Default configuration", groups: groups)
    return [configuration]
  }

  func use(_ configuration: KeyboardCowboyConfiguration) {
    configurationId = configuration.id
    // Select first group if the selection is empty
    if groupIds.isEmpty, let group = configuration.groups.first {
      groupIds = [group.id]
      groupStore.selectedGroups = [group]
    } else {
      selectGroupsIds(groupIds)
    }

    groupStore.groups = configuration.groups

    if workflowIds.isEmpty,
       let group = groupStore.groups.first,
       let workflow = group.workflows.first {
      workflowIds = [workflow.id]
      selectedWorkflows = [workflow]
    } else {
      selectWorkflowIds(workflowIds)
    }

    selectedWorkflowsCopy = selectedWorkflows
  }

  func selectGroupsIds(_ ids: Set<String>) {
    groupStore.selectedGroups = configurationStore.selectedConfiguration.groups
      .filter { ids.contains($0.id) }
    groupIds = Set<String>(groupStore.selectedGroups.compactMap({ $0.id }))

    let allWorkflowIds = groupStore.selectedGroups.flatMap { $0.workflows.compactMap { $0.id } }
    let workflowMatchesGroup = allWorkflowIds.filter { workflowIds.contains($0) }.isEmpty

    if workflowMatchesGroup, let workflow = groupStore.selectedGroups.first?.workflows.first {
      workflowIds = [workflow.id]
      selectedWorkflows = [workflow]
    }
  }

  func selectWorkflowIds(_ ids: Set<String>) {
    workflowIds = ids
    selectedWorkflows = groupStore.selectedGroups
      .flatMap {
        $0.workflows.filter { ids.contains($0.id) }
      }
    selectedWorkflowsCopy = selectedWorkflows
  }

  func updateWorkflows(_ newWorkflows: [Workflow]) {
    if selectedWorkflowsCopy == newWorkflows { return }

    Task(priority: .high) {
      let oldConfiguration = configurationStore.selectedConfiguration
      undoManager?.registerUndo(withTarget: self, handler: { contentStore in
        contentStore.applyConfiguration(oldConfiguration)
      })
      undoManager?.setActionName("Undo change")

      let newGroups = await groupStore.receive(newWorkflows)
      var newConfiguration = configurationStore.selectedConfiguration
      newConfiguration.groups = newGroups

      configurationStore.update(newConfiguration)
      selectGroupsIds(groupIds)
      let workflowIds = Set<String>(newWorkflows.compactMap({ $0.id }))
      selectWorkflowIds(workflowIds)
    }
  }

  // MARK: Private methods

  private func applyConfiguration(_ newConfiguration: KeyboardCowboyConfiguration) {
    let oldConfiguration = configurationStore.selectedConfiguration
    undoManager?.registerUndo(withTarget: self, handler: { contentStore in
      contentStore.applyConfiguration(oldConfiguration)
    })
    configurationStore.update(newConfiguration)
    selectGroupsIds(groupIds)
    selectWorkflowIds(workflowIds)
  }

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

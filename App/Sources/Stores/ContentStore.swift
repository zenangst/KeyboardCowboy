import Combine
import Foundation
import SwiftUI

@MainActor
final class ContentStore: ObservableObject {
  static var appStorage: AppStorageStore = .init()
  @Published private(set) var preferences: AppPreferences

  var undoManager: UndoManager?

  private let storage: Storage
  private let indexer: Indexer
  private var subscriptions = [AnyCancellable]()

  private(set) var applicationStore = ApplicationStore()
  private(set) var configurationStore: ConfigurationStore
  private(set) var groupStore: GroupStore
  private(set) var recorderStore = KeyShortcutRecorderStore()
  private(set) var shortcutStore: ShortcutStore
  
  @Published private var configurationId: String

  init(_ preferences: AppPreferences,
       indexer: Indexer,
       scriptEngine: ScriptEngine,
       workspace: NSWorkspace) {
    _configurationId = .init(initialValue: Self.appStorage.configId)

    let groupStore = GroupStore()
    self.shortcutStore = ShortcutStore(engine: scriptEngine)
    self.groupStore = groupStore
    self.configurationStore = ConfigurationStore()
    self.indexer = indexer
    self.preferences = preferences
    self.storage = Storage(preferences.storageConfiguration)

    guard !isRunningPreview else { return }

    Task {
      shortcutStore.index()
      let configurations: [KeyboardCowboyConfiguration]
      configurations = try await load()
      let shouldSave = configurations.isEmpty
      configurationStore.updateConfigurations(configurations)
      use(configurationStore.selectedConfiguration)
      storage.subscribe(to: configurationStore.$configurations)
      subscribe(to: groupStore.$groups)

      if shouldSave {
        try storage.save(configurationStore.configurations)
      }
    }
  }

  func load() async throws -> [KeyboardCowboyConfiguration] {
    let configurations: [KeyboardCowboyConfiguration]

    do {
      configurations = try await storage.load()
    } catch {
      do {
        configurations = try await migrateIfNeeded()
      } catch {
        configurations = []
      }
    }
    return configurations
  }

  func migrateIfNeeded() async throws -> [KeyboardCowboyConfiguration] {
    let groups: [WorkflowGroup] = try await storage.load()
    let configuration = KeyboardCowboyConfiguration(name: "Default configuration", groups: groups)
    return [configuration]
  }

  func use(_ configuration: KeyboardCowboyConfiguration) {
    indexer.createCache(configuration.groups)
    configurationId = configuration.id
    groupStore.groups = configuration.groups
  }

  func workflow(withId id: Workflow.ID) -> Workflow? {
    groupStore.workflow(withId: id)
  }

  // MARK: Private methods

  private func applyConfiguration(_ newConfiguration: KeyboardCowboyConfiguration) {
    let oldConfiguration = configurationStore.selectedConfiguration
    undoManager?.registerUndo(withTarget: self, handler: { contentStore in
      contentStore.applyConfiguration(oldConfiguration)
    })
    configurationStore.update(newConfiguration)
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

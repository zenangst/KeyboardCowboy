import Combine
import Foundation
import SwiftUI

@MainActor
final class ContentStore: ObservableObject {
  static var appStorage: AppStorageStore = .init()
  @Published private(set) var preferences: AppPreferences

  var undoManager: UndoManager?

  private let storage: Storage
  private let keyboardShortcutsCache: KeyboardShortcutsCache

  private var subscriptions = [AnyCancellable]()

  private(set) var configurationStore: ConfigurationStore
  private(set) var groupStore: GroupStore
  private(set) var recorderStore = KeyShortcutRecorderStore()
  private(set) var shortcutStore: ShortcutStore

  @Published private var configurationId: String
  let applicationStore: ApplicationStore

  init(_ preferences: AppPreferences,
       applicationStore: ApplicationStore,
       keyboardShortcutsCache: KeyboardShortcutsCache,
       shortcutStore: ShortcutStore,
       scriptEngine: ScriptEngine,
       workspace: NSWorkspace) {
    _configurationId = .init(initialValue: Self.appStorage.configId)

    let groupStore = GroupStore()
    self.applicationStore = applicationStore
    self.shortcutStore = shortcutStore
    self.groupStore = groupStore
    self.configurationStore = ConfigurationStore()
    self.keyboardShortcutsCache = keyboardShortcutsCache
    self.preferences = preferences
    self.storage = Storage(preferences.storageConfiguration)

    guard KeyboardCowboy.env != .designTime else { return }

    Task {
      Benchmark.start("ContentStore.init")
      await applicationStore.reload()
      shortcutStore.index()
      let configurations: [KeyboardCowboyConfiguration]
      configurations = try await storage.load()
      let shouldSave = configurations.isEmpty
      configurationStore.updateConfigurations(configurations)
      use(configurationStore.selectedConfiguration)
      storage.subscribe(to: configurationStore.$configurations)
      subscribe(to: groupStore.$groups)

      if shouldSave {
        try storage.save(configurationStore.configurations)
      }

      Benchmark.finish("ContentStore.init")
    }
  }

  func use(_ configuration: KeyboardCowboyConfiguration) {
    keyboardShortcutsCache.createCache(configuration.groups)
    configurationId = configuration.id
    configurationStore.select(configuration)
    groupStore.groups = configuration.groups
  }

  func workflow(withId id: Workflow.ID) -> Workflow? {
    groupStore.workflow(withId: id)
  }

  // MARK: Private methods

  @MainActor
  private func applyConfiguration(_ newConfiguration: KeyboardCowboyConfiguration) async {
    let oldConfiguration = configurationStore.selectedConfiguration
    undoManager?.registerUndo(withTarget: self, handler: { contentStore in
      Task { await contentStore.applyConfiguration(oldConfiguration) }
    })
    configurationStore.update(newConfiguration)
  }

  private func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    publisher
      .dropFirst()
      .removeDuplicates()
      .sink { [weak self] groups in
        self?.updateConfiguration(groups)

    }.store(in: &subscriptions)
  }

  private func updateConfiguration(_ groups: [WorkflowGroup]) {
    var newConfiguration = configurationStore.selectedConfiguration

    if newConfiguration.groups != groups {
      newConfiguration.groups = groups
      configurationStore.update(newConfiguration)
    }

    configurationStore.select(newConfiguration)
    use(newConfiguration)
  }

  private func generatePerformanceData() {
    for kind in Command.CodingKeys.allCases {
      var group = WorkflowGroup(name: "Group:\(kind.rawValue)")
      for x in 0..<100 {
        var workflow = Workflow(name: "Workflow:\(kind.rawValue):\(x + 1)")
        for y in 0..<100 {
          var command = Command.empty(kind)
          command.name = "Command:\(kind.rawValue):\(y+1)"
          workflow.commands.append(command)
        }
        group.workflows.append(workflow)
      }
      groupStore.add(group)
    }
  }
}

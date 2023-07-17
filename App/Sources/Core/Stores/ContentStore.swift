import Combine
import Foundation
import SwiftUI

@MainActor
final class ContentStore: ObservableObject {
  enum State {
    case loading
    case noConfiguration
    case initialized
  }

  static var appStorage: AppStorageStore = .init()
  @Published private(set) var state: State = .loading
  @Published private(set) var preferences: AppPreferences

  private let storage: Storage
  private let keyboardShortcutsController: KeyboardShortcutsController

  private var subscriptions = [AnyCancellable]()

  private(set) var configurationStore: ConfigurationStore
  private(set) var groupStore: GroupStore
  private(set) var recorderStore = KeyShortcutRecorderStore()
  private(set) var shortcutStore: ShortcutStore

  @Published private var configurationId: String
  let applicationStore: ApplicationStore

  init(_ preferences: AppPreferences,
       applicationStore: ApplicationStore,
       keyboardShortcutsController: KeyboardShortcutsController = .init(),
       shortcutStore shortcutStoreOverride: ShortcutStore? = nil,
       scriptCommandRunner: ScriptCommandRunner = .init(workspace: .shared),
       workspace: NSWorkspace = .shared) {
    _configurationId = .init(initialValue: Self.appStorage.configId)

    let groupStore = GroupStore()
    self.applicationStore = applicationStore
    self.shortcutStore = shortcutStoreOverride ?? ShortcutStore(scriptCommandRunner)
    self.groupStore = groupStore
    self.configurationStore = ConfigurationStore()
    self.keyboardShortcutsController = keyboardShortcutsController
    self.preferences = preferences
    self.storage = Storage(preferences.storageConfiguration)

    guard KeyboardCowboy.env != .designTime else { return }

    Task {
      Benchmark.start("ContentStore.init")
      await applicationStore.reload()
      shortcutStore.index()
      let configurations: [KeyboardCowboyConfiguration]

      do {
        configurations = try await storage.load()
        setup(configurations)
      } catch let error as StorageError {
        switch error {
        case .unableToFindFile:
          break
        case .unableToCreateFile:
          break
        case .unableToReadContents:
          break
        case .unableToSaveContents:
          break
        case .emptyFile:
          state = .noConfiguration
        }
      }

      Benchmark.finish("ContentStore.init")
    }
  }

  @MainActor
  func handle(_ action: EmptyConfigurationView.Action) {
    let configurations: [KeyboardCowboyConfiguration]
    switch action {
    case .empty:
      configurations = [.empty()]
    case .initial:
      configurations = [.default()]
    }
    setup(configurations)
    try? storage.save(configurationStore.configurations)
  }

  func use(_ configuration: KeyboardCowboyConfiguration) {
    keyboardShortcutsController.cache(configuration.groups)
    configurationId = configuration.id
    configurationStore.select(configuration)
    groupStore.groups = configuration.groups
  }

  func workflow(withId id: Workflow.ID) -> Workflow? {
    groupStore.workflow(withId: id)
  }

  // MARK: Private methods

  private func setup(_ configurations: [KeyboardCowboyConfiguration]) {
    configurationStore.updateConfigurations(configurations)
    use(configurationStore.selectedConfiguration)
    storage.subscribe(to: configurationStore.$configurations)
    subscribe(to: groupStore.$groups)
    state = .initialized
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
}

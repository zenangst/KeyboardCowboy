import Combine
import Foundation
import SwiftUI

@MainActor
final class ContentStore: ObservableObject {
  enum State: Equatable, Sendable {
    case loading
    case noConfiguration
    case initialized
  }

  @Published private(set) var state: State = .loading
  @Published private(set) var preferences: AppPreferences

  let storage: ConfigurationStorage

  private let shortcutResolver: ShortcutResolver

  private var subscriptions = [AnyCancellable]()

  private(set) var configurationStore: ConfigurationStore
  private(set) var groupStore: GroupStore
  private(set) var recorderStore: KeyShortcutRecorderStore
  private(set) var shortcutStore: ShortcutStore

  private var configurationId: String
  let applicationStore: ApplicationStore

  init(_ preferences: AppPreferences,
       applicationStore: ApplicationStore,
       configurationStore: ConfigurationStore,
       groupStore: GroupStore,
       shortcutResolver: ShortcutResolver,
       recorderStore: KeyShortcutRecorderStore,
       shortcutStore: ShortcutStore,
       scriptCommandRunner _: ScriptCommandRunner = .init(workspace: .shared),
       workspace _: NSWorkspace = .shared)
  {
    configurationId = AppStorageContainer.shared.configId
    self.applicationStore = applicationStore
    self.shortcutStore = shortcutStore
    self.groupStore = groupStore
    self.configurationStore = configurationStore
    self.shortcutResolver = shortcutResolver
    self.preferences = preferences
    storage = ConfigurationStorage(preferences.configLocation)
    self.recorderStore = recorderStore

    guard KeyboardCowboyApp.env() != .previews else { return }
    guard !launchArguments.isEnabled(.runningUnitTests) else { return }

    UserSpace.shared.subscribe(to: configurationStore.$selectedConfiguration)

    Task {
      Benchmark.shared.start("ContentStore.init")
      await applicationStore.load()
      await shortcutStore.index()
      let configurations: [KeyboardCowboyConfiguration]

      do {
        storage.backupIfNeeded()

        configurations = try await storage.load()
        setup(configurations)
      } catch let error as ConfigurationStorageError {
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

      Benchmark.shared.stop("ContentStore.init")
    }
  }

  @MainActor
  func handle(_ action: EmptyConfigurationView.Action) {
    let configurations: [KeyboardCowboyConfiguration] = switch action {
    case .empty:
      [.empty()]
    case .initial:
      [.default()]
    }
    setup(configurations)
    try? storage.save(configurationStore.configurations)
    NSApplication.shared.keyWindow?.close()
  }

  func use(_ configuration: KeyboardCowboyConfiguration) {
    Task {
      shortcutResolver.cache(configuration.groups)
    }
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
    shortcutStore.subscribe(to: UserSpace.shared.$frontmostApplication)
    state = .initialized
  }

  private func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    publisher
      .dropFirst()
      .removeDuplicates()
      .sink { [weak self] groups in
        self?.updateConfiguration(groups)
      }
      .store(in: &subscriptions)
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

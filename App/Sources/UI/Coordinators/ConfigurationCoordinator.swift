import Combine
import SwiftUI

@MainActor
final class ConfigurationCoordinator {
  private var subscription: AnyCancellable?

  private let contentStore: ContentStore
  private let selectionManager: SelectionManager<ConfigurationViewModel>
  private let store: ConfigurationStore

  let configurationsPublisher: ConfigurationsPublisher
  let configurationPublisher: ConfigurationPublisher

  init(contentStore: ContentStore, selectionManager: SelectionManager<ConfigurationViewModel>,
       store: ConfigurationStore) {
    self.contentStore = contentStore
    self.store = store
    self.selectionManager = selectionManager
    self.configurationsPublisher = ConfigurationsPublisher()
    self.configurationPublisher = ConfigurationPublisher(.init(id: UUID().uuidString, name: "", selected: false))

    Task {
      // TODO: Should we remove this subscription and make it more explicit when configurations change?
      // Why do we do this inside of a Task?
      subscription = store.$selectedConfiguration
        .sink { [weak self] configuration in
          guard let self else { return }

          self.configurationPublisher.publish(
            ConfigurationViewModel(
              id: configuration.id,
              name: configuration.name,
              selected: true,
              userModes: configuration.userModes
            )
          )
          self.render(selectedConfiguration: configuration)
          UserSpace.shared.setUserModes(configuration.userModes)
        }
    }
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .selectConfiguration(let id):
      if let configuration = store.selectConfiguration(withId: id) {
        contentStore.use(configuration)
        render(selectedConfiguration: configuration)
        selectionManager.publish([configuration.id])
      }
    case .addConfiguration(let name):
      let configuration = KeyboardCowboyConfiguration(
        id: UUID().uuidString,
        name: name,
        userModes: [],
        groups: []
      )
      store.add(configuration)
      contentStore.use(configuration)
      selectionManager.publish([configuration.id])
    case .updateConfiguration(let newName):
      var modifiedConfiguration = contentStore.configurationStore.selectedConfiguration
      modifiedConfiguration.name = newName
      contentStore.configurationStore.update(modifiedConfiguration)
      render(selectedConfiguration: modifiedConfiguration)
      selectionManager.publish([modifiedConfiguration.id])
    case .deleteConfiguration(let id):
      // Fix the bug when deleting configurations (they are out-of-sync)
      assert(contentStore.configurationStore.selectedConfiguration.id == id)
      contentStore.configurationStore.remove(contentStore.configurationStore.selectedConfiguration)
      if let firstConfiguration = contentStore.configurationStore.configurations.first {
        contentStore.use(firstConfiguration)
        render(selectedConfiguration: firstConfiguration)
      }
    case .userMode(let action):
      switch action {
      case .add(let string):
        let userMode = UserMode(id: UUID().uuidString, name: string, isEnabled: false)
        var modifiedConfiguration = contentStore.configurationStore.selectedConfiguration
        modifiedConfiguration.userModes.append(userMode)
        contentStore.configurationStore.update(modifiedConfiguration)
        contentStore.configurationStore.select(modifiedConfiguration)
      case .delete(let string):
        var modifiedConfiguration = contentStore.configurationStore.selectedConfiguration
        modifiedConfiguration.userModes.removeAll(where: { $0.id == string })
        contentStore.configurationStore.update(modifiedConfiguration)
        contentStore.configurationStore.select(modifiedConfiguration)
      case .rename(let id, let newName):
        var modifiedConfiguration = contentStore.configurationStore.selectedConfiguration
        guard let index = modifiedConfiguration.userModes.firstIndex(where: { $0.id == id }) else {
          return
        }
        modifiedConfiguration.userModes[index].name = newName
        contentStore.configurationStore.update(modifiedConfiguration)
        contentStore.configurationStore.select(modifiedConfiguration)
      }
    default:
      break
    }
  }

  private func render(selectedConfiguration: KeyboardCowboyConfiguration?) {
    var selections = [ConfigurationViewModel]()
    let configurations = store.configurations
      .map { configuration in
        let viewModel = ConfigurationViewModel(
          id: configuration.id,
          name: configuration.name,
          selected: selectedConfiguration?.id == configuration.id,
          userModes: configuration.userModes)

        if let selectedConfiguration, configuration.id == selectedConfiguration.id {
          selections.append(viewModel)
        }

        return viewModel
      }

    configurationsPublisher.publish(configurations)
  }
}

import Combine
import SwiftUI

@MainActor
final class ConfigurationCoordinator {
  private var subscription: AnyCancellable?
  let contentStore: ContentStore
  let store: ConfigurationStore
  let publisher: ConfigurationPublisher

  init(contentStore: ContentStore, store: ConfigurationStore) {
    self.contentStore = contentStore
    self.store = store
    self.publisher = ConfigurationPublisher()

    Task {
      subscription = store.$selectedConfiguration.sink(receiveValue: { [weak self] selectedConfiguration in
        self?.render(selectedConfiguration: selectedConfiguration)
      })
    }
  }

  func handle(_ action: SidebarView.Action) {
    Task {
      switch action {
      case .selectConfiguration(let id):
        if let configuration = store.selectConfiguration(withId: id) {
          contentStore.use(configuration)
        }
      case .addConfiguration(let name):
        let configuration = KeyboardCowboyConfiguration(id: UUID().uuidString, name: name, groups: [])
        store.add(configuration)
        contentStore.use(configuration)
      default:
        break
      }
    }
  }

  private func render(selectedConfiguration: KeyboardCowboyConfiguration?) {
    Task {
      var selections = [ConfigurationViewModel]()
      let configurations = store.configurations
        .map { configuration in
          let viewModel = ConfigurationViewModel(id: configuration.id, name: configuration.name)

          if let selectedConfiguration, configuration.id == selectedConfiguration.id {
            selections.append(viewModel)
          }

          return viewModel
        }

      publisher.publish(configurations, selections: selections.map(\.id))
    }
  }
}

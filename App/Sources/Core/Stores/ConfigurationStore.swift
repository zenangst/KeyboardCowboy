import Combine
import Foundation
import SwiftUI

@MainActor
final class ConfigurationStore: ObservableObject, @unchecked Sendable {
  @Published private(set) var configurations = [KeyboardCowboyConfiguration]()
  @Published private(set) var selectedConfiguration: KeyboardCowboyConfiguration = .empty()
  @State private(set) var selectedId: String = ""

  @discardableResult
  func updateConfigurations(_ configurations: [KeyboardCowboyConfiguration]) -> Self {
    self.configurations = configurations
    _selectedId = .init(initialValue: AppStorageContainer.shared.configId)

    if let configuration = configurations.first(where: { $0.id == selectedId }) {
      self.selectedConfiguration = configuration
      self.selectedId = configuration.id
    } else if let configuration = configurations.first  {
      self.selectedConfiguration = configuration
      self.selectedId = configuration.id
    } else {
      let configuration = KeyboardCowboyConfiguration(
        name: "Default configuration",
        userModes: [],
        groups: []
      )
      self.selectedConfiguration = configuration
      self.selectedId = configuration.id
      self.configurations = [configuration]
    }
    return self
  }

  func selectConfiguration(withId id: String) -> KeyboardCowboyConfiguration? {
    if let newConfiguration = configurations.first(where: { $0.id == id }) {
      selectedId = id
      selectedConfiguration = newConfiguration
      AppStorageContainer.shared.configId = id
      return newConfiguration
    } else {
      return nil
    }
  }

  func select(_ configuration: KeyboardCowboyConfiguration) {
    selectedId = configuration.id
    selectedConfiguration = configuration
  }

  func add(_ configuration: KeyboardCowboyConfiguration) {
    configurations.append(configuration)
  }

  func remove(_ configuration: KeyboardCowboyConfiguration) {
    configurations.removeAll(where: { $0.id == configuration.id })
  }

  @MainActor
  func update(_ configuration: KeyboardCowboyConfiguration) {
    guard let index = configurations.firstIndex(where: { $0.id == configuration.id }) else {
      return
    }

    var newConfigurations = self.configurations

    guard newConfigurations[index] != configuration else { return }

    newConfigurations[index] = configuration
    if KeyboardCowboyApp.env() == .production {
      select(configuration)
    }
    self.configurations = newConfigurations
  }
}

import SwiftUI

struct ConfigurationContainerView: View {
  private let configSelection: SelectionManager<ConfigurationViewModel>
  private let onAction: (SidebarView.Action) -> Void

  init(configSelection: SelectionManager<ConfigurationViewModel>,
       onAction: @escaping (SidebarView.Action) -> Void) {
    self.configSelection = configSelection
    self.onAction = onAction
  }

  var body: some View {
    ConfigurationHeaderView()
      .padding(.horizontal, 12)
    ConfigurationView(configSelection) { action in
      switch action {
      case .deleteConfiguration(let id):
        onAction(.deleteConfiguration(id: id))
      case .updateName(let newName):
        onAction(.updateConfiguration(name: newName))
      case .addConfiguration(let name):
        onAction(.addConfiguration(name: name))
      case .selectConfiguration(let id):
        onAction(.selectConfiguration(id))
      }
    }
    .padding([.leading, .top, .trailing], 12)
  }
}

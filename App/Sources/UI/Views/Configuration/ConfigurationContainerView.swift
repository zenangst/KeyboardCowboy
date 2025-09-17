import Bonzai
import Inject
import SwiftUI

struct ConfigurationContainerView: View {
  @ObserveInjection var inject
  private let configSelection: SelectionManager<ConfigurationViewModel>
  private let onAction: (SidebarView.Action) -> Void

  init(configSelection: SelectionManager<ConfigurationViewModel>,
       onAction: @escaping (SidebarView.Action) -> Void)
  {
    self.configSelection = configSelection
    self.onAction = onAction
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ZenLabel(.sidebar) { Text("Configuration") }
      ConfigurationView(configSelection) { action in
        switch action {
        case let .deleteConfiguration(id):
          onAction(.deleteConfiguration(id: id))
        case let .updateName(newName):
          onAction(.updateConfiguration(name: newName))
        case let .addConfiguration(name):
          onAction(.addConfiguration(name: name))
        case let .selectConfiguration(id):
          onAction(.selectConfiguration(id))
        }
      }
    }
    .padding(.top, topPadding())
    .enableInjection()
  }

  func topPadding() -> CGFloat {
    if #available(macOS 26.0, *) {
      return 8
    } else {
      return 32
    }
  }
}

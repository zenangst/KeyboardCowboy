import Bonzai
import SwiftUI

struct SidebarDeleteConfigurationPopoverView: View {
  @Binding private var deleteConfigurationPopover: Bool
  private let id: ConfigurationViewModel.ID
  private let configurationName: String
  private let selectionManager: SelectionManager<ConfigurationViewModel>
  private let onAction: (ConfigurationViewModel.ID) -> Void

  init(_ deleteConfigurationPopover: Binding<Bool>,
       id: ConfigurationViewModel.ID,
       configurationName: String,
       selectionManager: SelectionManager<ConfigurationViewModel>,
       onAction: @escaping (ConfigurationViewModel.ID) -> Void)
  {
    _deleteConfigurationPopover = deleteConfigurationPopover
    self.id = id
    self.configurationName = configurationName
    self.selectionManager = selectionManager
    self.onAction = onAction
  }

  var body: some View {
    VStack {
      Text("Are you sure you want to delete '") +
        Text(configurationName).bold() +
        Text("'?")
      HStack {
        Spacer()
        Button("Abort", action: {
          deleteConfigurationPopover = false
        })
        .keyboardShortcut(.cancelAction)
        Button("Confirm", action: {
          onAction(id)
          deleteConfigurationPopover = false
        })
      }
    }
    .padding()
  }
}

struct SidebarDeleteConfigurationPopoverView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarDeleteConfigurationPopoverView(.constant(true),
                                          id: UUID().uuidString,
                                          configurationName: "Default",
                                          selectionManager: SelectionManager([]),
                                          onAction: { _ in })
  }
}

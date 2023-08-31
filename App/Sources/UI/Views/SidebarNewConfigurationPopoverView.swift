import SwiftUI

struct SidebarNewConfigurationPopoverView: View {
  @Binding private var newConfigurationPopover: Bool
  @State private var configurationName: String
  private let onAction: (String) -> Void

  init(_ newConfigurationPopover: Binding<Bool>,
       configurationName: String,
       onAction: @escaping (String) -> Void) {
    _configurationName = .init(initialValue: configurationName)
    _newConfigurationPopover = newConfigurationPopover
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      Text("Configuration name:")
      TextField("", text: $configurationName)
        .frame(width: 170)
        .onSubmit {
          onAction(configurationName)
          newConfigurationPopover = false
          configurationName = ""
        }
      Button("Save", action: {
        onAction(configurationName)
        newConfigurationPopover = false
        configurationName = ""
      })
      .keyboardShortcut(.defaultAction)
      .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, hoverEffect: false)))
    }
    .padding()
  }
}

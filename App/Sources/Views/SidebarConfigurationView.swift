import SwiftUI

struct SidebarConfigurationView: View {
  enum Action {
    case addConfiguration(name: String)
    case selectConfiguration(ConfigurationViewModel.ID)
  }
  @EnvironmentObject private var publisher: ConfigurationPublisher
  @ObservedObject var selectionManager: SelectionManager<ConfigurationViewModel>

  @State var popoverIsPresented = false
  @State var configurationName: String = ""

  private let onAction: (Action) -> Void

  init(_ selectionManager: SelectionManager<ConfigurationViewModel>, onAction: @escaping (Action) -> Void) {
    self.selectionManager = selectionManager
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      HStack {
        Menu {
          ForEach(publisher.data) { configuration in
            Button(action: { onAction(.selectConfiguration(configuration.id)) },
                   label: { Text(configuration.name) })
          }
        } label: {
          Text(publisher.data.first(where: { $0.selected })?.name ?? "Missing value" )
            .lineLimit(1)
            .fixedSize(horizontal: false, vertical: true)
            .allowsTightening(true)
            .contentShape(Rectangle())
        }
        .menuStyle(IconMenuStyle())
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.disabledControlTextColor))
        }
      )

      Button(action: {
        popoverIsPresented = true
      }, label: {
        Image(systemName: "plus.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: 12)
          .padding(2)
      })
      .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
      .popover(isPresented: $popoverIsPresented) {
        HStack {
          Text("Configuration name:")
          TextField("", text: $configurationName)
            .frame(width: 170)
          Button("Save", action: {
            onAction(.addConfiguration(name: configurationName))
            popoverIsPresented = false
            configurationName = ""
          })
            .keyboardShortcut(.defaultAction)
        }
        .padding()
      }
    }
    .debugEdit()
  }
}

struct SidebarConfigurationView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarConfigurationView(.init()) { _ in }
      .designTime()
  }
}

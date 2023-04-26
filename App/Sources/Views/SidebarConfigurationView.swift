import SwiftUI

struct SidebarConfigurationView: View {
  enum Action {
    case addConfiguration(name: String)
    case selectConfiguration(ConfigurationViewModel.ID)
  }
  @EnvironmentObject private var publisher: ConfigurationPublisher

  @State var popoverIsPresented = false
  @State var configurationName: String = ""

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
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
          HStack {
            // TODO: Fix this!
            Text(publisher.data.first(where: { publisher.selections.contains($0.id) })?.name ?? "Missing value" )
              .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
          }
          .fixedSize(horizontal: false, vertical: true)
          .allowsTightening(true)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        Spacer()
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 4)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.disabledControlTextColor))
        }
      )

      Button(action: {
        popoverIsPresented = true
      }, label: {
        Image(systemName: "plus")
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
    SidebarConfigurationView { _ in }
      .designTime()
  }
}

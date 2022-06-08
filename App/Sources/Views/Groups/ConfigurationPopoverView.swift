import Cocoa
import SwiftUI

struct ConfigurationPopoverView: View {
  enum Action {
    case select(KeyboardCowboyConfiguration)
    case edit(KeyboardCowboyConfiguration)
    case remove(KeyboardCowboyConfiguration)
    case newConfiguration
  }
  @FocusState var focus: Focus?
  @ObservedObject var store: ConfigurationStore

  var action: (Action) -> Void

  var body: some View {
    VStack {
      ScrollView {
        VStack(spacing: 0) {
          ForEach(store.configurations) { configuration in
            ResponderView(configuration, action: { _ in
              ResponderChain.shared.makeFirstResponder(configuration)
              action(.select(configuration))
            }) { responder in
              HStack(spacing: 0) {
                VStack(alignment: .leading) {
                  Text(configuration.name)
                  if configuration.id == store.selectedId {
                    Text("Current")
                      .font(.caption)
                      .foregroundColor( responder.isFirstReponder ? .white : .accentColor)
                  }
                }
                Spacer()

                Button("Edit", action: {
                  action(.edit(configuration))
                })
                .font(.footnote)
                .buttonStyle(KCButtonStyle())
              }
              .frame(height: 32)
              .padding(8)
              .background(backgroundView(responder))
              .padding(.top, 4)
              .onTapGesture {
                ResponderChain.shared.makeFirstResponder(configuration)
                if responder.isFirstReponder {
                  action(.select(configuration))
                }
              }
            }
          }
        }.padding(8)
      }
      .focused($focus, equals: .sidebar(.configuration))

      Button.init("New configuration", action: { action(.newConfiguration) })
        .buttonStyle(KCButtonStyle())
        .padding([.leading, .bottom, .trailing])
        .onAppear {
          focus = .sidebar(.configuration)
        }
    }
  }

  @ViewBuilder
  func backgroundView(_ responder: Responder) -> some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color(.gridColor).opacity(0.25))
    ResponderBackgroundView(responder: responder)
  }
}

struct ConfigurationPopoverView_Previews: PreviewProvider {
  static let store = ConfigurationStore()
    .updateConfigurations([
      KeyboardCowboyConfiguration(name: "Default", groups: []),
      KeyboardCowboyConfiguration(name: "Work", groups: []),
      KeyboardCowboyConfiguration(name: "Personal", groups: []),
    ])

  static var previews: some View {
    ConfigurationPopoverView(store: store, action: { _ in })
  }
}

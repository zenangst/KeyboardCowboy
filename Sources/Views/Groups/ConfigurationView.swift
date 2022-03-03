import SwiftUI

struct ConfigurationView: View {
  enum Action {
    case ok(Configuration)
    case cancel
  }

  @ObservedObject var store: ConfigurationStore
  @State var configuration: Configuration

  var action: (Action) -> Void

  init(_ store: ConfigurationStore, action: @escaping (Action) -> Void) {
    _store = .init(initialValue: store)
    _configuration = .init(initialValue: store.selectedConfiguration)
    self.action = action
  }

  var body: some View {
    VStack(alignment: .leading) {
      VStack {
        Label("Configurations", image: "")
          .labelStyle(HeaderLabelStyle())
      }.padding([.top, .leading])

//      VStack(alignment: .leading) {
//        Label("Current configuration", image: "")
//          .labelStyle(HeaderLabelStyle())
//        HStack {
//          Text("Name:")
//          TextField("Configuration name", text: $configuration.name)
//            .onSubmit {
//              action(.ok(configuration))
//            }
//        }
//      }
//      .padding()
//
//      Divider()

      ScrollView {
        ForEach(store.configurations) { configuration in
          VStack {
            ResponderView { responder in
              HStack {
                VStack(alignment: .leading) {
                  Text(configuration.name)
                  if configuration.id == store.selectedId {
                    Text("Current")
                      .font(.caption)
                      .foregroundColor(.accentColor)
                  }
                }
                Spacer()
              }
              .frame(height: 32)
              .padding(8)
              .background(ResponderBackgroundView(responder: responder))
              .padding([.top, .bottom], 8)
              .padding([.leading, .trailing])
            }
          }
        }
      }

      Divider()

      HStack {
        Spacer()
        Button("Cancel", role: .cancel, action: {
          action(.cancel)
        })
        .keyboardShortcut(.cancelAction)

        Button("OK", action: {
          action(.ok(configuration))
        })
        .keyboardShortcut(.defaultAction)
      }
      .padding([.leading, .trailing, .bottom])
    }
    .frame(alignment: .topLeading)
  }
}

struct ConfigurationView_Previews: PreviewProvider {
  // Pictures
  static let store = ConfigurationStore()
    .updateConfigurations([
      Configuration(name: "Default", groups: []),
      Configuration(name: "Personal", groups: []),
      Configuration(name: "Work", groups: [])
    ])
  static var previews: some View {
    ConfigurationView(store, action: { _ in })
      .frame(minWidth: 320)
  }
}

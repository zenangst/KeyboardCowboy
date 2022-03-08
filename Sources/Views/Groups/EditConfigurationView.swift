import SwiftUI

struct EditConfigurationView: View {
  enum Action {
    case ok(KeyboardCowboyConfiguration)
    case cancel
  }

  @ObservedObject var store: ConfigurationStore
  @State var configuration: KeyboardCowboyConfiguration

  var action: (Action) -> Void

  init(_ store: ConfigurationStore, action: @escaping (Action) -> Void) {
    _store = .init(initialValue: store)
    _configuration = .init(initialValue: store.selectedConfiguration)
    self.action = action
  }

  var body: some View {
    VStack(alignment: .leading) {
      VStack(alignment: .leading) {
        Label("Edit configuration", image: "")
          .labelStyle(HeaderLabelStyle())
        HStack {
          Text("Name:")
          TextField("Configuration name", text: $configuration.name)
            .onSubmit {
              action(.ok(configuration))
            }
        }
      }
      .padding()

      Divider()

      HStack {
        Spacer()
        Button("Cancel", role: .cancel, action: {
          action(.cancel)
        })
        .buttonStyle(KCButtonStyle())
        .keyboardShortcut(.cancelAction)

        Button("OK", action: {
          action(.ok(configuration))
        })
        .buttonStyle(KCButtonStyle())
        .keyboardShortcut(.defaultAction)
      }
      .padding([.leading, .trailing, .bottom])
    }
    .frame(alignment: .topLeading)
  }
}

struct EditConfigurationView_Previews: PreviewProvider {
  // Pictures
  static let store = ConfigurationStore()
    .updateConfigurations([
      KeyboardCowboyConfiguration(name: "Default", groups: []),
      KeyboardCowboyConfiguration(name: "Personal", groups: []),
      KeyboardCowboyConfiguration(name: "Work", groups: [])
    ])
  static var previews: some View {
    EditConfigurationView(store, action: { _ in })
      .frame(minWidth: 320)
  }
}

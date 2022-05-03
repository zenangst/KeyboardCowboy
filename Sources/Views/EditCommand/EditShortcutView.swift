import SwiftUI

struct EditShortcutView: View {
  @ObserveInjection var inject

  @State var command: ShortcutCommand {
    willSet { update(newValue) }
  }
  @State var selection: String = ""
  @ObservedObject var store: ShortcutStore

  let update: (ShortcutCommand) -> Void

  init(command: ShortcutCommand, store: ShortcutStore, update: @escaping (ShortcutCommand) -> Void) {
    _command = .init(initialValue: command)
    _store = .init(initialValue: store)
    _selection = .init(initialValue: command.shortcutIdentifier)
    self.update = update
  }

  var body: some View {
    Group {
      VStack(spacing: 0) {
        HStack {
          Text("Run Shortcut")
            .font(.title)
          Spacer()
        }
        .padding()
        Divider()
      }

      VStack(spacing: 0) {
        Picker("Shortcut:",
               selection: Binding<String>(
                get: { selection },
                set: { newValue in
                  selection = newValue
                  self.command = ShortcutCommand(id: command.id, shortcutIdentifier: newValue,
                                                 name: "Run '\(newValue)'",
                                                 isEnabled: true)
                }
               )) {
          ForEach(store.shortcuts, id: \.name) { shortcut in
            Text("\(shortcut.name)")
              .id(shortcut.name)
          }
        }
      }
      .padding()
    }
    .enableInjection()
  }
}

struct EditShortcutView_Previews: PreviewProvider {
  static var previews: some View {
    EditShortcutView(command: ShortcutCommand.empty(), store: ShortcutStore()) { _ in }
  }
}

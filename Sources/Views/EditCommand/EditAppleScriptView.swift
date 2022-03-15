import SwiftUI

struct EditAppleScriptView: View {
  @State var command: ScriptCommand {
    willSet { update(newValue) }
  }
  @State var filePath: String
  let openPanelController: OpenPanelController
  var update: (ScriptCommand) -> Void

  init(command: ScriptCommand,
       openPanelController: OpenPanelController,
       update: @escaping (ScriptCommand) -> Void) {
    self._command = State(initialValue: command)
    self._filePath = State(initialValue: command.path)
    self.openPanelController = openPanelController
    self.update = update
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Apple script").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        LazyVGrid(columns: [
          GridItem(.fixed(50), alignment: .trailing),
          GridItem(.flexible())
        ], content: {
          Text("Name:")
          TextField(command.name, text: Binding(get: {
            command.hasName ? command.name : ""
          }, set: {
            command = .appleScript(id: command.id,
                                   isEnabled: command.isEnabled,
                                   name: $0.isEmpty ? nil : $0,
                                   source: .path(command.path))
          }))

          Text("Path:")
          TextField("file://", text: Binding<String>(get: {
            filePath
          }, set: {
            filePath = $0
            command = .appleScript(id: command.id,
                                   isEnabled: command.isEnabled,
                                   name: command.name,
                                   source: .path($0))
          }))
        })

        HStack {
          Spacer()
          Button("Browse", action: {
            openPanelController.perform(.selectFile(type: "sh", handler: {
              let newCommand = ScriptCommand.appleScript(id: command.id,
                                                         isEnabled: command.isEnabled,
                                                         name: command.name,
                                                         source: .path($0))
              command = newCommand
              filePath = newCommand.path
            }))
          })
        }
      }.padding()
    }
  }
}

struct EditAppleScriptView_Previews: PreviewProvider {
  static var previews: some View {
    EditAppleScriptView(command: .empty(.appleScript),
                        openPanelController: OpenPanelController(),
                        update: { _ in })
  }

}

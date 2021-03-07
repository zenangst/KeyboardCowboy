import SwiftUI
import ModelKit

struct EditAppleScriptView: View {
  @Binding var command: ScriptCommand
  @State var filePath: String
  let openPanelController: OpenPanelController

  init(command: Binding<ScriptCommand>,
       openPanelController: OpenPanelController) {
    _command = command
    _filePath = State(initialValue: command.wrappedValue.path)
    self.openPanelController = openPanelController
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
                                   name: $0.isEmpty ? nil : $0,
                                   source: .path(command.path))
          }))

          Text("Path:")
          TextField("file://", text: Binding<String>(get: {
            filePath
          }, set: {
            filePath = $0
            command = .appleScript(id: command.id,
                             name: command.name,
                             source: .path($0))
          }))
        })

        HStack {
          Spacer()
          Button("Browse", action: {
            openPanelController.perform(.selectFile(type: "sh", handler: {
              let newCommand = ScriptCommand.appleScript(id: command.id, name: command.name, source: .path($0))
              command = newCommand
              filePath = newCommand.path
            }))
          })
        }
      }.padding()
    }
  }
}

struct EditAppleScriptView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
      EditAppleScriptView(
        command: .constant(ScriptCommand.empty(.appleScript)),
        openPanelController: OpenPanelPreviewController().erase())
    }
}

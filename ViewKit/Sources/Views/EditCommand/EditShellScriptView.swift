import SwiftUI
import ModelKit

struct EditShellScriptView: View {
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
        Text("Shellscript").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        HStack {
          Text("Path:")
          TextField("file://", text: Binding(get: {
            filePath
          }, set: {
            filePath = $0
            command = .shell(.path($0), command.id)
          }))
        }
        HStack {
          Spacer()
          Button("Browse", action: {
            openPanelController.perform(.selectFile(type: "sh", handler: {
              let newCommand = ScriptCommand.shell(.path($0), command.id)
              command = newCommand
              filePath = newCommand.path
            }))
          })
        }
      }.padding()
    }
  }
}

struct EditShellScriptView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    EditShellScriptView(
      command: .constant(ScriptCommand.empty(.shell)),
      openPanelController: OpenPanelPreviewController().erase())
  }
}

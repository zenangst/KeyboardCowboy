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
        HStack {
          Text("Path:")
          TextField("file://", text: Binding(get: {
            filePath
          }, set: {
            filePath = $0
            command = ScriptCommand.appleScript(.path($0), command.id)
          }))
        }
        HStack {
          Spacer()
          Button("Browse", action: {
            openPanelController.perform(.selectFile(type: "scpt", handler: {
              let newCommand = ScriptCommand.appleScript(.path($0), command.id)
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

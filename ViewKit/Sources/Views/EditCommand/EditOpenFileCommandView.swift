import SwiftUI
import ModelKit

struct EditOpenFileCommandView: View {
  @Binding var command: OpenCommand
  @State var filePath: String
  let openPanelController: OpenPanelController

  init(command: Binding<OpenCommand>,
       openPanelController: OpenPanelController) {
    _command = command
    _filePath = State(initialValue: command.wrappedValue.path)
    self.openPanelController = openPanelController
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Open a file").font(.title)
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
            command = OpenCommand(id: command.id, path: $0)
          }))
        }
        HStack {
          Spacer()
          Button("Browse", action: {
            openPanelController.perform(.selectFile(type: nil, handler: {
              let newCommand = OpenCommand(id: command.id, path: $0)
              command = newCommand
              filePath = newCommand.path
            }))
          })
        }
      }.padding()
    }
  }
}

struct EditOpenFileCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    EditOpenFileCommandView(
      command: .constant(OpenCommand(path: "")),
      openPanelController: OpenPanelPreviewController().erase())
  }
}

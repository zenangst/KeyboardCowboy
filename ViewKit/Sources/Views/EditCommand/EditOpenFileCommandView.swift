import SwiftUI
import ModelKit

struct EditOpenFileCommandView: View {
  @ObservedObject var openPanelController: OpenPanelController
  @Binding var command: OpenCommand

  init(command: Binding<OpenCommand>,
       openPanelController: OpenPanelController) {
    self._command = command
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
            command.path
          }, set: {
            command = OpenCommand(id: command.id, path: $0)
          }))
        }
        HStack {
          Spacer()
          Button("Browse", action: {
            openPanelController.perform(.selectFile(type: nil, handler: {
              command = OpenCommand(id: command.id, path: $0)
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

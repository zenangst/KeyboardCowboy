import SwiftUI
import ModelKit

struct EditOpenFileCommandView: View {
  @Binding var command: OpenCommand
  @ObservedObject var openPanelController: OpenPanelController

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

private final class OpenPanelPreviewController: ViewController {
  let state = ""
  func perform(_ action: OpenPanelAction) {}
}

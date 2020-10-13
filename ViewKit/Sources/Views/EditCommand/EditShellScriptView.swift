import SwiftUI
import ModelKit

struct EditShellScriptView: View {
  @ObservedObject var openPanelController: OpenPanelController
  @Binding var command: ScriptCommand

  init(command: Binding<ScriptCommand>,
       openPanelController: OpenPanelController) {
    self._command = command
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
            if case .shell(let source, _) = command,
               case .path(let value) = source {
              return value
            }
            return ""
          }, set: {
            command = .shell(.path($0), command.id)
          }))
        }
        HStack {
          Spacer()
          Button("Browse", action: {
            openPanelController.perform(.selectFile(type: "sh", handler: {
              command = .shell(.path($0), command.id)
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

private final class OpenPanelPreviewController: ViewController {
  let state = ""
  func perform(_ action: OpenPanelAction) {}
}

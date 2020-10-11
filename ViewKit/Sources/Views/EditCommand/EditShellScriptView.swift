import SwiftUI

struct EditShellScriptView: View {
  @ObservedObject var openPanelController: OpenPanelController
  @Binding var commandViewModel: CommandViewModel

  init(commandViewModel: Binding<CommandViewModel>,
       openPanelController: OpenPanelController) {
    self._commandViewModel = commandViewModel
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
            if case .shellScript(let viewModel) = commandViewModel.kind {
              return viewModel.path
            }
            return ""
          }, set: {
            commandViewModel.kind = .shellScript(ShellScriptViewModel(path: $0))
          }))
        }
        HStack {
          Spacer()
          Button("Browse", action: {
            openPanelController.perform(.selectFile(type: "sh", handler: {
              commandViewModel.kind = .shellScript(ShellScriptViewModel(path: $0))
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
      commandViewModel: .constant(
        CommandViewModel(name: "", kind: .shellScript(ShellScriptViewModel.empty()))
      ),
      openPanelController: OpenPanelPreviewController().erase())
  }
}

private final class OpenPanelPreviewController: ViewController {
  let state = ""
  func perform(_ action: OpenPanelAction) {}
}

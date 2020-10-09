import SwiftUI

struct EditOpenFileCommandView: View {
  @ObservedObject var openPanelController: OpenPanelController
  @Binding var commandViewModel: CommandViewModel
  @State var tabSelection: Int = 1
  @State var path: String
  var internalState: Binding<String>?

  init(commandViewModel: Binding<CommandViewModel>,
       openPanelController: OpenPanelController) {
    self._commandViewModel = commandViewModel
    self.openPanelController = openPanelController
    self._path = State(initialValue: "")
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
          TextField("file://", text: $path)
        }
        HStack {
          Spacer()
          Button("Browse", action: {
            openPanelController.perform(.selectFile(type: nil, handler: {
              commandViewModel.kind = .openFile(OpenFileViewModel(path: $0))
              path = $0
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
      commandViewModel: .constant(
        CommandViewModel(name: "", kind: .openFile(OpenFileViewModel.empty()))
      ),
      openPanelController: OpenPanelPreviewController().erase())
  }
}

private final class OpenPanelPreviewController: ViewController {
  let state = ""
  func perform(_ action: OpenPanelAction) {}
}

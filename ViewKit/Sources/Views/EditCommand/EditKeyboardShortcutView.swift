import SwiftUI

struct EditKeyboardShortcutView: View {
  @Binding var commandViewModel: CommandViewModel
  @ObservedObject var openPanelController: OpenPanelController

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Run Keyboard Shortcut").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        KeyboardShortcutView(keyboardShortcut: Binding(
                              get: {
                                if case .keyboard(let viewModel) = commandViewModel.kind {
                                  return viewModel
                                }
                                return nil
                              },
                              set: { keyboardShortcut in
                                if let keyboardShortcut = keyboardShortcut {
                                  commandViewModel.kind = .keyboard(keyboardShortcut)
                                }
                              }))
      }
      .padding()
    }
  }
}

struct EditKeyboardShortcutView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    EditOpenFileCommandView(
      commandViewModel: .constant(
        CommandViewModel(name: "", kind: .keyboard(KeyboardShortcutViewModel.empty()))
      ),
      openPanelController: OpenPanelPreviewController().erase())
  }
}

private final class OpenPanelPreviewController: ViewController {
  let state = ""
  func perform(_ action: OpenPanelAction) {}
}

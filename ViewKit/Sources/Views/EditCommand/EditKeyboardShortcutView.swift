import SwiftUI
import ModelKit

struct EditKeyboardShortcutView: View {
  @Binding var command: KeyboardCommand

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Run Keyboard Shortcut").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        KeyboardRecorderView(
          keyboardShortcut: Binding(
            get: { command.keyboardShortcut },
            set: { keyboardShortcut in
              if let keyboardShortcut = keyboardShortcut {
                command = KeyboardCommand(id: command.id, keyboardShortcut: keyboardShortcut)
              } else {
                command = KeyboardCommand(id: command.id, keyboardShortcut: KeyboardShortcut.empty())
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
    EditKeyboardShortcutView(
      command: .constant(KeyboardCommand.empty()))
  }
}

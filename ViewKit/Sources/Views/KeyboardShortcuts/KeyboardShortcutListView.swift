import SwiftUI

struct KeyboardShortcutListView: View {
  public enum Action {
    case createKeyboardShortcut
    case updateKeyboardShortcut(KeyboardShortcutViewModel)
    case deleteKeyboardShortcut(KeyboardShortcutViewModel)
  }

  let keyboardShortcuts: [KeyboardShortcutViewModel]

  var body: some View {
    VStack(spacing: 0) {
      ForEach(keyboardShortcuts) { keyboardShortcut in
        HStack {
          Text("1.").padding(.horizontal, 4)
          KeyboardShortcutView(keyboardShortcut: .constant(keyboardShortcut))
          HStack(spacing: 4) {
            Button("+", action: {  })
            Button("-", action: {  })
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .cornerRadius(8.0)
        .tag(keyboardShortcut)
        Divider()
      }

      HStack(spacing: 2) {
        Spacer()
        Button("Add Keyboard Shortcut", action: {})
          .buttonStyle(LinkButtonStyle())
      }.padding([.top, .trailing], 10)
    }
    .padding(.bottom, 10)
  }
}

// MARK: - Previews

struct KeyboardShortcutListView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardShortcutListView(keyboardShortcuts: ModelFactory().keyboardShortcuts())
  }
}

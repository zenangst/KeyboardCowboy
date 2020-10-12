import SwiftUI

struct KeyboardCommandView: View {
  let command: CommandViewModel
  let editAction: (CommandViewModel) -> Void
  let showContextualMenu: Bool

  var body: some View {
    HStack {
      ZStack {
        IconView(icon: Icon(identifier: "keyboard-shortcut", path: "/System/Library/PreferencePanes/Keyboard.prefPane"))
          .frame(width: 32, height: 32)
      }
      VStack(alignment: .leading, spacing: 0) {
        Text(command.name)
        if showContextualMenu {
          HStack(spacing: 4) {
            Button("Edit", action: { editAction(command) })
              .foregroundColor(Color(.controlAccentColor))
          }.buttonStyle(LinkButtonStyle())
          .font(Font.caption)
        }
      }
    }
  }
}

struct KeyboardCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardCommandView(
      command: CommandViewModel(
        id: UUID().uuidString,
        name: "Run keyboard shortcut ⌘F",
        kind: .keyboard(KeyboardShortcutViewModel(index: 1, key: "F", modifiers: [.command]))),
      editAction: { _ in },
      showContextualMenu: true)
  }
}

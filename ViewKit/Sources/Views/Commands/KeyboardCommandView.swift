import SwiftUI

struct KeyboardCommandView: View {
  let command: CommandViewModel

  var body: some View {
    HStack {
      ZStack {
        IconView(identifier: "keyboard-shortcut", path: "/System/Library/PreferencePanes/Keyboard.prefPane")
          .frame(width: 32, height: 32)
      }
      VStack(alignment: .leading, spacing: 0) {
        Text(command.name)
        HStack(spacing: 4) {
          Button("Change", action: {})
            .foregroundColor(Color(.controlAccentColor))
        }.buttonStyle(LinkButtonStyle())
        .font(Font.caption)
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
        kind: .keyboard))
  }
}

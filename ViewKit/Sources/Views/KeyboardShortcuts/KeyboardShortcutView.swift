import SwiftUI
import ModelKit

struct KeyboardShortcutView: View {
  let shortcut: ModelKit.KeyboardShortcut

  var body: some View {
    HStack(spacing: 0) {
      Text("\(shortcut.modifersDisplayValue)")
        .foregroundColor(.secondary)
      Text("\(shortcut.key)")
    }
    .padding(1)
    .padding(.horizontal, 4)
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .stroke(Color(.separatorColor), lineWidth: 1)
    )
  }
}

struct ShortcutView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardShortcutView(shortcut:
      .init(key: "C", modifiers: [.command])
    )
  }
}

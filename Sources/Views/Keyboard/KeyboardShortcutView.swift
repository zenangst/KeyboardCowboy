import SwiftUI

struct KeyboardShortcutView: View {
  let shortcut: KeyShortcut

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

struct ShortcutView_Previews: PreviewProvider {
  static var previews: some View {
    KeyboardShortcutView(shortcut:
      .init(key: "C", modifiers: [.command])
    )
  }
}

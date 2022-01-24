import SwiftUI

struct KeyShortcutsListView: View {
  @State var keyboardShortcuts: [KeyShortcut]

  var body: some View {
    HStack {
      HStack {
        if keyboardShortcuts.isEmpty {
         RegularKeyIcon(letter: "Record keyboard shortcut")
            .fixedSize()
        } else {
          ForEach(keyboardShortcuts, id: \.self) { keyboardShortcut in
            key(keyboardShortcut)
              .overlay(
                RoundedRectangle(cornerRadius: 4)
                  .stroke(
                    Color(NSColor.systemGray.withSystemEffect(.disabled)),
                    lineWidth: 1)
              )
          }
        }
      }
      .frame(height: 36)

      Spacer()
      Button(action: {},
             label: { Image(systemName: "plus.square.fill") })
        .buttonStyle(PlainButtonStyle())
        .padding(.trailing, 4)
    }
    .padding(4)
    .background(Color(.windowBackgroundColor))
    .cornerRadius(4)
    .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
  }

  func key(_ keyboardShortcut: KeyShortcut) -> some View {
    HStack(spacing: 4) {
      if let modifiers = keyboardShortcut.modifiers,
         !modifiers.isEmpty {
        ForEach(modifiers) { modifier in
          ModifierKeyIcon(key: modifier)
            .frame(minWidth: modifier == .shift || modifier == .command ? 48 : 32, maxWidth: 48)
        }
      }

      if keyboardShortcut.key.lowercased() == "space" {
        RegularKeyIcon(letter: "\(keyboardShortcut.key)",
                       glow: false)
          .frame(width: 64)
          .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
      } else {
        RegularKeyIcon(letter: "\(keyboardShortcut.key)",
                       glow: false)
          .frame(width: 32)
          .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
      }
    }
    .padding(2)
  }
}

struct KeyShortcutsListView_Previews: PreviewProvider {
    static var previews: some View {
      KeyShortcutsListView(keyboardShortcuts: [
        .init(key: "↑"),
        .init(key: "↑"),

        .init(key: "↓"),
        .init(key: "↓"),

        .init(key: "←"),
        .init(key: "→"),

        .init(key: "←"),
        .init(key: "→"),

        .init(key: "B"),
        .init(key: "A"),
      ])
    }
}

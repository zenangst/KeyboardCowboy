import SwiftUI

struct EditKeyboardShortcutView: View {
  // swiftlint:disable weak_delegate
  @Binding var command: KeyboardCommand
  @State var selection: KeyShortcut?

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Run Keyboard Shortcut").font(.title)
        Spacer()
      }.padding()
      Divider()
      Spacer().frame(height: 8)
      HStack(spacing: 8) {
        key(command.keyboardShortcut)
          .onTapGesture {
            selection = command.keyboardShortcut
          }
          .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
      }
      .padding(4)
    }
  }

  func key(_ keyboardShortcut: KeyShortcut) -> some View {
    HStack {
      Spacer()
      if let modifiers = keyboardShortcut.modifiers,
         !modifiers.isEmpty {
        ForEach(modifiers) { modifier in
          ModifierKeyIcon(key: modifier)
            .frame(minWidth: modifier == .shift || modifier == .command ? 48 : 32, maxWidth: 48)
        }
      }

      RegularKeyIcon(letter: keyboardShortcut.key.isEmpty ? "Record keyboard shortcut" : keyboardShortcut.key,
                     glow: selection == command.keyboardShortcut)
      Spacer()
    }
    .frame(height: 32)
    .padding(.vertical, 4)
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .stroke(
          selection == command.keyboardShortcut
            ? Color(.controlAccentColor)
            : Color(NSColor.systemGray.withSystemEffect(.disabled)),
          lineWidth: 1)
    )
  }
}

struct EditKeyboardShortcutView_Previews: PreviewProvider {

  static let examples: [KeyboardCommand] = [
    KeyboardCommand.empty(),
    KeyboardCommand.init(keyboardShortcut: .init(key: "A", modifiers: [.command])),
    KeyboardCommand.init(keyboardShortcut: .init(key: "C", modifiers: [.control, .option, .command])),
    KeyboardCommand.init(keyboardShortcut: .init(key: "W", modifiers: [])),
  ]

  static var previews: some View {
    VStack {
      ForEach(Self.examples) { command in
        EditKeyboardShortcutView(
          command: .constant(command))
      }
    }
  }
}

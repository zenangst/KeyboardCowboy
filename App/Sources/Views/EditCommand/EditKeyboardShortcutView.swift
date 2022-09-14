import SwiftUI

struct EditKeyboardShortcutView: View {
  // swiftlint:disable weak_delegate
  @ObserveInjection var inject
  @Binding var command: KeyboardCommand
  @ObservedObject var recorderStore: KeyShortcutRecorderStore
  @State var selection: KeyShortcut?

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Run Keyboard Shortcut").font(.title)
        Spacer()
      }.padding()
      Divider()
      Spacer().frame(height: 8)
      // TODO: Fix bug where UI doesn't update properly after editing a shortcut.
      HStack(spacing: 8) {
        key(command.keyboardShortcut)
          .onTapGesture {
            selection = command.keyboardShortcut
            recorderStore.mode = .record
          }
          .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
      }
      .onReceive(recorderStore.$recording) { recording in
        if case .valid(let keyboardShortcut) = recording {
          command = .init(keyboardShortcut: keyboardShortcut)
          selection = command.keyboardShortcut
        }
      }
      .padding(4)
    }
    .enableInjection()
  }

  func key(_ keyboardShortcut: KeyShortcut) -> some View {
    HStack {
      Spacer()
      if let modifiers = keyboardShortcut.modifiers,
         !modifiers.isEmpty {
        ForEach(modifiers) { modifier in
          ModifierKeyIcon(
            key: modifier,
            alignment: keyboardShortcut.lhs
            ? .topTrailing
            : .topLeading)
          .frame(minWidth: modifier == .shift || modifier == .command ? 48 : 32, maxWidth: 48)
        }
      }

      RegularKeyIcon(
        letter: keyboardShortcut.key.isEmpty ? "Record keyboard shortcut" : keyboardShortcut.key,
        glow: .constant(selection == command.keyboardShortcut))
      .fixedSize()
      .id(keyboardShortcut.key)
      Spacer()
    }
    .frame(height: 32)
    .padding(4)
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
    KeyboardCommand.init(keyboardShortcut: .init(key: "A", lhs: true, modifiers: [.command])),
    KeyboardCommand.init(keyboardShortcut: .init(key: "C", lhs: true, modifiers: [.control, .option, .command])),
    KeyboardCommand.init(keyboardShortcut: .init(key: "W", lhs: true, modifiers: [])),
  ]

  static var previews: some View {
    VStack {
      ForEach(Self.examples) { command in
        EditKeyboardShortcutView(
          command: .constant(command),
          recorderStore: KeyShortcutRecorderStore())
      }
    }
  }
}

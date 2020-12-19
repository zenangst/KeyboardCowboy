import BridgeKit
import SwiftUI
import ModelKit

struct EditKeyboardShortcutView: View {
  // swiftlint:disable weak_delegate
  @StateObject var transportDelegate = TransportDelegate()
  @Binding var command: KeyboardCommand
  @State var selection: ModelKit.KeyboardShortcut?

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Run Keyboard Shortcut").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        item(command.keyboardShortcut)
          .onTapGesture {
            TransportController.shared.receiver = transportDelegate
            NotificationCenter.default.post(.enableRecordingHotKeys)
            selection = command.keyboardShortcut
          }
      }
      .padding([.leading, .trailing], 4)
      .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
      .padding()
    }.onReceive(transportDelegate.$state, perform: { context in
      guard let context = context,
            let selection = selection else {
        return
      }

      switch context {
      case .delete, .cancel, .systemShortcut:
        break
      case .valid(let keyboardShortcut):
        let updatedKeyboardShortcut = ModelKit.KeyboardShortcut(
          id: selection.id,
          key: keyboardShortcut.key,
          modifiers: keyboardShortcut.modifiers)
        let keyboardCommand = KeyboardCommand(
          id: command.id, name: command.name,
          keyboardShortcut: updatedKeyboardShortcut)
        command = keyboardCommand
      }
      self.selection = nil
    })
  }

  func item(_ keyboardShortcut: ModelKit.KeyboardShortcut) -> some View {
    KeyboardSequenceItem(
      title: keyboardShortcut.modifersDisplayValue,
      subtitle: keyboardShortcut.key.isEmpty ? "Record keyboard shortcut" : keyboardShortcut.key
    )
      .frame(minWidth: 32)
      .padding(2)
      .foregroundColor(
        Color(selection == keyboardShortcut
                ? NSColor.controlAccentColor.withSystemEffect(.pressed)
                : NSColor.textColor
        )
      )
      .background(
        Color(selection == keyboardShortcut
                ? NSColor.controlAccentColor.withAlphaComponent(0.33)
                : NSColor.textBackgroundColor
        )
      )
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(
            selection == keyboardShortcut
              ? Color(.controlAccentColor)
              : Color(NSColor.systemGray.withSystemEffect(.disabled)),
            lineWidth: 1)
      )
      .cornerRadius(4)
      .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
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

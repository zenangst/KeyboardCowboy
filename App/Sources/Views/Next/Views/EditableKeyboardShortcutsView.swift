import SwiftUI

struct EditableKeyboardShortcutsView: View {
  @ObserveInjection var inject
  @Binding var keyboardShortcuts: [KeyShortcut]

  var body: some View {
    ScrollView(.horizontal) {
      EditableStack(
        $keyboardShortcuts,
        axes: .horizontal,
        onMove: { keyboardShortcuts.move(fromOffsets: $0, toOffset: $1) },
        onDelete: { offsets in
          withAnimation(.easeOut(duration: 0.2)) {
            keyboardShortcuts.remove(atOffsets: offsets)
          }
        },
        content: { keyboardShortcut in
        HStack(spacing: 6) {
          ForEach(keyboardShortcut.wrappedValue.modifiers) { modifier in
            ModifierKeyIcon(key: modifier)
              .frame(minWidth: modifier == .command || modifier == .shift ? 44 : 32, minHeight: 32)
              .fixedSize(horizontal: true, vertical: true)
          }
          RegularKeyIcon(letter: keyboardShortcut.wrappedValue.key, width: 32, height: 32)
            .fixedSize(horizontal: true, vertical: true)
        }
        .contextMenu {
          Text(keyboardShortcut.wrappedValue.validationValue)
          Divider()
          Button(action: {
            if let index = keyboardShortcuts.firstIndex(where: { $0.id == keyboardShortcut.id }) {
              _ = withAnimation(.easeOut(duration: 0.2)) {
                keyboardShortcuts.remove(at: index)
              }
            }
          }, label: {
            Text("Remove")
          })
        }
        .padding(4)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(Color(.disabledControlTextColor))
            .opacity(0.5)
        )
      })
      .padding(4)
    }
    .enableInjection()
  }
}

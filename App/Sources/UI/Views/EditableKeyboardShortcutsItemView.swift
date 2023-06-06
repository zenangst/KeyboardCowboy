import SwiftUI

struct EditableKeyboardShortcutsItemView: View {
  @State var isTargeted: Bool = false
  let focusPublisher: FocusPublisher<KeyShortcut>
  let keyboardShortcut: Binding<KeyShortcut>
  @Binding var keyboardShortcuts: [KeyShortcut]
  let selectionManager: SelectionManager<KeyShortcut>

  var body: some View {
    HStack(spacing: 6) {
      ForEach(keyboardShortcut.wrappedValue.modifiers) { modifier in
        ModifierKeyIcon(
          key: modifier,
          alignment: keyboardShortcut.wrappedValue.lhs
          ? modifier == .shift ? .bottomLeading : .topTrailing
          : modifier == .shift ? .bottomTrailing : .topLeading
        )
        .frame(minWidth: modifier == .command || modifier == .shift ? 44 : 32, minHeight: 32)
        .fixedSize(horizontal: true, vertical: true)
      }
      RegularKeyIcon(letter: keyboardShortcut.wrappedValue.key, width: 32, height: 32)
        .fixedSize(horizontal: true, vertical: true)
    }
    .contentShape(Rectangle())
    .padding(4)
    .background(
      FocusView(focusPublisher, element: keyboardShortcut,
                isTargeted: $isTargeted,
                selectionManager: selectionManager, cornerRadius: 8, style: .focusRing)
    )
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(Color(.disabledControlTextColor))
        .opacity(0.5)
    )
    .draggable(keyboardShortcut.draggablePayload(prefix: "WKS|", selections: selectionManager.selections))
    .dropDestination(for: String.self) { items, location in
      guard let payload = items.draggablePayload(prefix: "WKS|"),
            let (from, destination) = keyboardShortcuts.moveOffsets(for: keyboardShortcut.wrappedValue,
                                                                    with: payload) else {
        return false
      }
      withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
        keyboardShortcuts.move(fromOffsets: IndexSet(from), toOffset: destination)
      }
      return true
    } isTargeted: { newValue in
      isTargeted = newValue
    }
  }
}

struct EditableKeyboardShortcutsItemView_Previews: PreviewProvider {
    static var previews: some View {
      EditableKeyboardShortcutsItemView(
        focusPublisher: .init(),
        keyboardShortcut: .constant(.init(key: UUID().uuidString, lhs: true)),
        keyboardShortcuts: .constant([]),
        selectionManager: .init())
    }
}

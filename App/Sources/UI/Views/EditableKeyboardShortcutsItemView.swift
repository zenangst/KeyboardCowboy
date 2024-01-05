import Bonzai
import Inject
import SwiftUI

struct EditableKeyboardShortcutsItemView: View {
  @ObserveInjection var inject
  @State var isHovered: Bool = false
  @State var isTargeted: Bool = false
  let keyboardShortcut: Binding<KeyShortcut>
  @Binding var keyboardShortcuts: [KeyShortcut]
  let selectionManager: SelectionManager<KeyShortcut>
  let onDelete: (KeyShortcut) -> Void

  var body: some View {
    HStack(spacing: 6) {
      ForEach(keyboardShortcut.wrappedValue.modifiers) { modifier in
        ModifierKeyIcon(
          key: modifier,
          alignment: keyboardShortcut.wrappedValue.lhs
          ? modifier == .shift ? .bottomLeading : .topTrailing
          : modifier == .shift ? .bottomTrailing : .topLeading,
          glow: .constant(false)
        )
        .frame(minWidth: modifier == .command || modifier == .shift ? 40 : 30, minHeight: 30)
        .fixedSize(horizontal: true, vertical: true)
      }
      RegularKeyIcon(letter: keyboardShortcut.wrappedValue.key, width: 30, height: 30, glow: .constant(false))
        .fixedSize(horizontal: true, vertical: true)
    }
    .contentShape(Rectangle())
    .padding(2)
    .overlay(BorderedOverlayView(cornerRadius: 4))
    .overlay(alignment: .topTrailing, content: {
      Button(action: {
        onDelete(keyboardShortcut.wrappedValue)
      }, label: {
        Image(systemName: "xmark.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 12)
      })
      .buttonStyle(.borderless)
      .scaleEffect(isHovered ? 1 : 0.5)
      .opacity(isHovered ? 1 : 0)
      .animation(.smooth, value: isHovered)
    })
    .background(
      RoundedRectangle(cornerRadius: 5, style: .continuous)
        .stroke(Color(.disabledControlTextColor).opacity(0.6))
        .opacity(0.5)
    )
    .padding(.horizontal, 2)
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
    .onHover(perform: { hovering in
      isHovered = hovering
    })
    .enableInjection()
  }
}

struct EditableKeyboardShortcutsItemView_Previews: PreviewProvider {
    static var previews: some View {
      EditableKeyboardShortcutsItemView(
        keyboardShortcut: .constant(.init(key: UUID().uuidString, lhs: true)),
        keyboardShortcuts: .constant([]),
        selectionManager: .init(), onDelete: { _ in })
      .padding()
    }
}

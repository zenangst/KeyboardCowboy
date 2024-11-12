import Bonzai
import Inject
import SwiftUI

struct EditableKeyboardShortcutsItemView: View {
  enum Feature {
    case record
    case remove
  }

  @Binding private var keyboardShortcuts: [KeyShortcut]

  private let features: Set<Feature>
  private let keyboardShortcut: Binding<KeyShortcut>
  private let selectionManager: SelectionManager<KeyShortcut>
  private let onDelete: (KeyShortcut) -> Void

  init(keyboardShortcut: Binding<KeyShortcut>,
       keyboardShortcuts: Binding<[KeyShortcut]>,
       features: Set<Feature>,
       selectionManager: SelectionManager<KeyShortcut>,
       onDelete: @escaping (KeyShortcut) -> Void) {
    _keyboardShortcuts = keyboardShortcuts
    self.keyboardShortcut = keyboardShortcut
    self.selectionManager = selectionManager
    self.onDelete = onDelete
    self.features = features
  }

  var body: some View {
    EditableKeyboardShortcutsItemInternalView(
      keyboardShortcuts: $keyboardShortcuts,
      keyboardShortcut: keyboardShortcut,
      features: features,
      selectionManager: selectionManager,
      onDelete: onDelete
    )
  }
}

private struct EditableKeyboardShortcutsItemInternalView: View {
  @Binding private var keyboardShortcuts: [KeyShortcut]

  @State private var isHovered: Bool = false
  @State private var isTargeted: Bool = false

  private let features: Set<EditableKeyboardShortcutsItemView.Feature>
  private let keyboardShortcut: Binding<KeyShortcut>
  private let selectionManager: SelectionManager<KeyShortcut>
  private let onDelete: (KeyShortcut) -> Void

  init(keyboardShortcuts: Binding<[KeyShortcut]>, keyboardShortcut: Binding<KeyShortcut>,
       features: Set<EditableKeyboardShortcutsItemView.Feature>,
       selectionManager: SelectionManager<KeyShortcut>, onDelete: @escaping (KeyShortcut) -> Void) {
    _keyboardShortcuts = keyboardShortcuts
    self.features = features
    self.keyboardShortcut = keyboardShortcut
    self.selectionManager = selectionManager
    self.onDelete = onDelete
  }

  var body: some View {
    HStack(spacing: 6) {
      ForEach(keyboardShortcut.wrappedValue.modifiers) { modifier in
        let largerModifiers: [ModifierKey] = [
          .leftCommand, .rightCommand,
          .leftShift, .rightShift,
          .capsLock
        ]
        ModifierKeyIcon(
          key: modifier,
          glow: .constant(false)
        )
        .frame(minWidth: largerModifiers.contains(modifier) ? 40 : 30, minHeight: 30)
        .fixedSize(horizontal: true, vertical: true)
      }
      RegularKeyIcon(letter: keyboardShortcut.wrappedValue.key, width: 30, height: 30, glow: .constant(false))
        .fixedSize(horizontal: true, vertical: true)
    }
    .contentShape(Rectangle())
    .padding(2)
    .overlay(BorderedOverlayView(.readonly(selectionManager.selections.contains(keyboardShortcut.wrappedValue.id)), cornerRadius: 4))
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
      .opacity(isHovered && features.contains(.remove) ? 1 : 0)
      .animation(.smooth, value: isHovered)
    })
    .background(
      RoundedRectangle(cornerRadius: 5, style: .continuous)
        .stroke(Color(.disabledControlTextColor).opacity(0.6))
        .opacity(0.5)
    )
    .padding(.horizontal, 2)
    .onHover(perform: { hovering in
      isHovered = hovering
    })
  }
}

struct EditableKeyboardShortcutsItemView_Previews: PreviewProvider {
    static var previews: some View {
      EditableKeyboardShortcutsItemView(
        keyboardShortcut: .constant(.init(key: "Caps Lock", modifiers: [.capsLock])),
        keyboardShortcuts: .constant([]),
        features: [.remove],
        selectionManager: .init(), onDelete: { _ in })
      .padding()
    }
}

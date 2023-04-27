import SwiftUI

struct WorkflowShortcutsView: View {
  @State private var keyboardShortcuts: [KeyShortcut]
  private let onUpdate: ([KeyShortcut]) -> Void

  init(_ keyboardShortcuts: [KeyShortcut], onUpdate: @escaping ([KeyShortcut]) -> Void) {
    _keyboardShortcuts = .init(initialValue: keyboardShortcuts)
    self.onUpdate = onUpdate
  }

  var body: some View {
    EditableKeyboardShortcutsView(keyboardShortcuts: $keyboardShortcuts)
      .frame(minHeight: 48)
      .padding(.trailing, 6)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(.textBackgroundColor).opacity(0.65))
      )
      .onChange(of: keyboardShortcuts, perform: { newValue in
        onUpdate(newValue)
      })
      .debugEdit()
  }
}

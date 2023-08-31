import SwiftUI

struct WorkflowShortcutsView: View {
  var focus: FocusState<AppFocus?>.Binding
  @State private var data: [KeyShortcut]
  private let onUpdate: ([KeyShortcut]) -> Void
  private let selectionManager: SelectionManager<KeyShortcut>

  init(_ focus: FocusState<AppFocus?>.Binding, data: [KeyShortcut],
       selectionManager: SelectionManager<KeyShortcut>,
       onUpdate: @escaping ([KeyShortcut]) -> Void) {
    self.focus = focus
    self.selectionManager = selectionManager
    _data = .init(initialValue: data)
    self.onUpdate = onUpdate
  }

  var body: some View {
    EditableKeyboardShortcutsView($data, selectionManager: selectionManager, onTab: {
      if $0 {
        focus.wrappedValue = .detail(.commands)
      } else {
        focus.wrappedValue = .detail(.name)
      }
    })
      .frame(minHeight: 48, maxHeight: 48)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(.textBackgroundColor).opacity(0.65))
      )
      .padding(.vertical, 6)
      .onChange(of: data, perform: { newValue in
        onUpdate(newValue)
      })
      .focused(focus, equals: .detail(.keyboardShortcuts))
  }
}

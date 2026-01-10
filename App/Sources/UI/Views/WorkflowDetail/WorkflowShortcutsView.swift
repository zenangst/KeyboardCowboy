import Bonzai
import HotSwiftUI
import SwiftUI

struct WorkflowShortcutsView: View {
  @ObserveInjection var inject
  @Binding private var data: [KeyShortcut]
  private var focus: FocusState<AppFocus?>.Binding
  private let onUpdate: ([KeyShortcut]) -> Void
  private let selectionManager: SelectionManager<KeyShortcut>

  init(_ focus: FocusState<AppFocus?>.Binding,
       data: Binding<[KeyShortcut]>,
       selectionManager: SelectionManager<KeyShortcut>,
       onUpdate: @escaping ([KeyShortcut]) -> Void) {
    _data = data
    self.focus = focus
    self.onUpdate = onUpdate
    self.selectionManager = selectionManager
  }

  var body: some View {
    EditableKeyboardShortcutsView<AppFocus>(focus,
                                            focusBinding: { .detail(.keyboardShortcut($0)) },
                                            mode: .inlineEdit,
                                            keyboardShortcuts: $data,
                                            draggableEnabled: true,
                                            selectionManager: selectionManager,
                                            recordOnAppearIfEmpty: true,
                                            onTab: {
                                              if $0 {
                                                focus.wrappedValue = .detail(.commands)
                                              } else {
                                                focus.wrappedValue = .detail(.name)
                                              }
                                            })
                                            .style(.list)
                                            .roundedSubStyle(8, padding: 0)
                                            .frame(minHeight: 42, maxHeight: 42)
                                            .onChange(of: data, perform: { newValue in
                                              onUpdate(newValue)
                                            })
                                            .focused(focus, equals: .detail(.keyboardShortcuts))
                                            .enableInjection()
  }
}

struct WorkflowShortcutsView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowShortcutsView($focus,
                          data: .constant([]),
                          selectionManager: .init(),
                          onUpdate: {
                            _ in
                          })
                          .designTime()
                          .padding()
  }
}

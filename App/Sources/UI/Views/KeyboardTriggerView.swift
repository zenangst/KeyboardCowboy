import Combine
import SwiftUI

struct KeyboardTriggerView: View {
  private let data: DetailViewModel
  private let namespace: Namespace.ID
  private let onAction: (SingleDetailView.Action) -> Void
  @State private var trigger: DetailViewModel.KeyboardTrigger
  private let focus: FocusState<AppFocus?>.Binding
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>

  @State private var holdDurationText = ""
  @State private var passthrough: Bool

  init(namespace: Namespace.ID,
       focus: FocusState<AppFocus?>.Binding,
       data: DetailViewModel,
       trigger: DetailViewModel.KeyboardTrigger,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.namespace = namespace
    self.focus = focus
    self.data = data
    _trigger = .init(initialValue: trigger)
    self.onAction = onAction
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    if let holdDuration = trigger.holdDuration {
      _holdDurationText = .init(initialValue: String(Int(holdDuration)))
    }
    _passthrough = .init(initialValue: trigger.passthrough)
  }

  var body: some View {
    VStack {
      HStack {
        Button(action: {
          onAction(.removeTrigger(workflowId: data.id))
        },
               label: { Image(systemName: "xmark") })
        .buttonStyle(.appStyle)
        Label("Keyboard Shortcuts sequence:", image: "")
          .padding(.trailing, 12)
        Spacer()
        AppCheckbox("Passthrough", isOn: $passthrough) { newValue in
          onAction(.togglePassthrough(workflowId: data.id, newValue: newValue))
        }
        .font(.caption)
      }
      .padding([.leading, .trailing], 8)
      
      WorkflowShortcutsView(focus, data: trigger.shortcuts, selectionManager: keyboardShortcutSelectionManager) { keyboardShortcuts in
        onAction(.updateKeyboardShortcuts(workflowId: data.id, 
                                          passthrough: passthrough,
                                          holdDuration: Double(holdDurationText),
                                          keyboardShortcuts: keyboardShortcuts))
      }
      .matchedGeometryEffect(id: "workflow-triggers", in: namespace)
      
      if trigger.shortcuts.count == 1 {
        HStack {
          Spacer()
          Text("Hold for")
          IntegerTextField(text: $holdDurationText) {
            onAction(.updateHoldDuration(workflowId: data.id, holdDuration: Double($0)))
          }
          .textFieldStyle(AppTextFieldStyle(.caption))
          .frame(maxWidth: 32)
          Text("seconds")
        }
        .font(.caption2)
      }
    }
  }
}


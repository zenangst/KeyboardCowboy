import Bonzai
import Combine
import Inject
import SwiftUI

struct WorkflowKeyboardTriggerView: View {
  @ObserveInjection var inject
  @State private var holdDurationText = ""
  @State private var passthrough: Bool
  @State private var trigger: DetailViewModel.KeyboardTrigger
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>
  private let namespace: Namespace.ID
  private let onAction: (SingleDetailView.Action) -> Void
  private let workflowId: String
  private var focus: FocusState<AppFocus?>.Binding

  init(namespace: Namespace.ID,
       workflowId: String,
       focus: FocusState<AppFocus?>.Binding,
       trigger: DetailViewModel.KeyboardTrigger,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.namespace = namespace
    self.workflowId = workflowId
    self.focus = focus
    _trigger = .init(initialValue: trigger)

    if let holdDuration = trigger.holdDuration {
      _holdDurationText = .init(initialValue: String(Double(holdDuration)))
    }
    _passthrough = .init(initialValue: trigger.passthrough)

    self.onAction = onAction
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
  }

  var body: some View {
    VStack(spacing: 8) {
      WorkflowShortcutsView(focus, data: $trigger.shortcuts, selectionManager: keyboardShortcutSelectionManager) { keyboardShortcuts in
        onAction(.updateKeyboardShortcuts(workflowId: workflowId,
                                          passthrough: passthrough,
                                          holdDuration: Double(holdDurationText),
                                          keyboardShortcuts: keyboardShortcuts))
      }

      HStack {
        ZenCheckbox("Passthrough", style: .small, isOn: $passthrough) { newValue in
          onAction(.togglePassthrough(workflowId: workflowId, newValue: newValue))
        }
        .font(.caption)
        Spacer()
        if trigger.shortcuts.count == 1 {
          Text("Hold for")
          NumberTextField(text: $holdDurationText) {
            onAction(.updateHoldDuration(workflowId: workflowId, holdDuration: Double($0)))
          }
          .textFieldStyle(.zen(.init(backgroundColor: Color(nsColor: .controlColor).opacity(0.5), font: .caption, padding: .small)))
          .frame(maxWidth: 32)
          Text("seconds")
        }
      }
      .font(.caption2)
    }
    .padding(.horizontal, 8)
    .enableInjection()
  }
}

struct KeyboardTriggerView_Previews: PreviewProvider {
  @Namespace static var namespace
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowKeyboardTriggerView(namespace: namespace,
                        workflowId: UUID().uuidString,
                        focus: $focus,
                        trigger: .init(passthrough: false, shortcuts: [
                          .empty()
                        ]),
                        keyboardShortcutSelectionManager: .init(),
                        onAction: {
      _ in
    })
    .designTime()
    .padding()
  }
}

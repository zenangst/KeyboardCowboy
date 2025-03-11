import Bonzai
import Combine
import Inject
import SwiftUI

struct WorkflowKeyboardTriggerView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @ObserveInjection var inject
  @State private var holdDurationText = ""
  @State private var allowRepeat: Bool
  @State private var keepLastPartialMatch: Bool
  @State private var passthrough: Bool
  @State private var trigger: DetailViewModel.KeyboardTrigger
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>
  private let namespace: Namespace.ID
  private let workflowId: String
  private var focus: FocusState<AppFocus?>.Binding

  init(namespace: Namespace.ID,
       workflowId: String,
       focus: FocusState<AppFocus?>.Binding,
       trigger: DetailViewModel.KeyboardTrigger,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>) {
    self.namespace = namespace
    self.workflowId = workflowId
    self.focus = focus
    _trigger = .init(initialValue: trigger)

    if let holdDuration = trigger.holdDuration {
      _holdDurationText = .init(initialValue: String(Double(holdDuration)))
    }
    _keepLastPartialMatch = .init(initialValue: trigger.keepLastPartialMatch)
    _passthrough = .init(initialValue: trigger.passthrough)
    _allowRepeat = .init(initialValue: trigger.allowRepeat)

    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
  }

  var body: some View {
    VStack(spacing: 8) {
      WorkflowShortcutsView(focus, data: $trigger.shortcuts, selectionManager: keyboardShortcutSelectionManager) { keyboardShortcuts in
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.trigger = .keyboardShortcuts(
            KeyboardShortcutTrigger(
              allowRepeat: allowRepeat,
              keepLastPartialMatch: keepLastPartialMatch,
              passthrough: passthrough,
              holdDuration: Double(holdDurationText),
              shortcuts: keyboardShortcuts))
        }
      }

      HStack {
        Toggle(isOn: $allowRepeat, label: { Text("Allow Repeat") })
          .onChange(of: allowRepeat, perform: { newValue in
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .keyboardShortcuts(
                KeyboardShortcutTrigger(
                  allowRepeat: newValue,
                  keepLastPartialMatch: keepLastPartialMatch,
                  passthrough: passthrough,
                  holdDuration: Double(holdDurationText),
                  shortcuts: trigger.shortcuts))
            }
          })

        Toggle(isOn: $keepLastPartialMatch, label: {
          Text("Keep Last Partial Match")
        })
          .onChange(of: keepLastPartialMatch, perform: { newValue in
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .keyboardShortcuts(
                KeyboardShortcutTrigger(
                  allowRepeat: allowRepeat,
                  keepLastPartialMatch: newValue,
                  passthrough: passthrough,
                  holdDuration: Double(holdDurationText),
                  shortcuts: trigger.shortcuts))
            }
          })

        Toggle(isOn: $passthrough, label: { Text("Passthrough") })
          .onChange(of: passthrough, perform: { newValue in
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .keyboardShortcuts(
                KeyboardShortcutTrigger(
                  allowRepeat: allowRepeat,
                  keepLastPartialMatch: keepLastPartialMatch,
                  passthrough: newValue,
                  holdDuration: Double(holdDurationText),
                  shortcuts: trigger.shortcuts))
            }
          })
        Spacer()
        HStack(spacing: 0) {
          if trigger.shortcuts.count == 1 {
            Text("Hold for")
          } else {
            Text("Become modifier after")
          }
        }
        NumberTextField(text: $holdDurationText) { newValue in
          updater.modifyWorkflow(using: transaction) { workflow in
            workflow.trigger = .keyboardShortcuts(
              KeyboardShortcutTrigger(
                allowRepeat: allowRepeat,
                keepLastPartialMatch: keepLastPartialMatch,
                passthrough: passthrough,
                holdDuration: Double(newValue),
                shortcuts: trigger.shortcuts))
          }
        }
        .textFieldStyle { style in
          style.cornerRadius = 4
          style.backgroundColor = Color(nsColor: .controlColor).opacity(0.5)
          style.font = .caption
          style.padding = .small
        }
        .frame(maxWidth: 32)
        Text("seconds")
      }
      .font(.caption)
      .checkboxStyle { checkbox in
        checkbox.font = .caption
        checkbox.style = .small
      }
    }
    .textStyle { text in
      text.font = .caption
    }
    .lineLimit(1)
    .truncationMode(.middle)
    .allowsTightening(true)
    .enableInjection()
  }
}

struct KeyboardTriggerView_Previews: PreviewProvider {
  @Namespace static var namespace
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowKeyboardTriggerView(
      namespace: namespace,
      workflowId: UUID().uuidString,
      focus: $focus,
      trigger: DetailViewModel.KeyboardTrigger(
        allowRepeat: true,
        keepLastPartialMatch: false,
        passthrough: false,
        shortcuts: [
          .empty()
        ]
      ),
      keyboardShortcutSelectionManager: .init()
    )
    .designTime()
    .padding()
  }
}

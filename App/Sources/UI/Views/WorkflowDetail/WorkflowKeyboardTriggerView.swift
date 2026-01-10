import Bonzai
import Combine
import HotSwiftUI
import SwiftUI

struct WorkflowKeyboardTriggerView: View {
  @EnvironmentObject private var publisher: TriggerPublisher
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @ObserveInjection var inject
  @State private var holdForDuration: Double
  @State private var allowRepeat: Bool
  @State private var keepLastPartialMatch: Bool
  @State private var passthrough: Bool
  @State private var leaderKey: Bool
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
      _holdForDuration = .init(initialValue: holdDuration)
    } else {
      _holdForDuration = .init(initialValue: 0)
    }
    _keepLastPartialMatch = .init(initialValue: trigger.keepLastPartialMatch)
    _passthrough = .init(initialValue: trigger.passthrough)
    _allowRepeat = .init(initialValue: trigger.allowRepeat)
    _leaderKey = .init(initialValue: trigger.leaderKey)

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
              leaderKey: leaderKey,
              passthrough: passthrough,
              holdDuration: holdForDuration == 0 ? nil : holdForDuration,
              shortcuts: keyboardShortcuts,
            ))
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
                  leaderKey: leaderKey,
                  passthrough: passthrough,
                  holdDuration: holdForDuration == 0 ? nil : holdForDuration,
                  shortcuts: trigger.shortcuts,
                ))
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
                leaderKey: leaderKey,
                passthrough: passthrough,
                holdDuration: holdForDuration == 0 ? nil : holdForDuration,
                shortcuts: trigger.shortcuts,
              ))
          }
        })

        Toggle(isOn: $passthrough, label: { Text("Passthrough") })
          .onChange(of: passthrough, perform: { newValue in
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .keyboardShortcuts(
                KeyboardShortcutTrigger(
                  allowRepeat: allowRepeat,
                  keepLastPartialMatch: keepLastPartialMatch,
                  leaderKey: leaderKey,
                  passthrough: newValue,
                  holdDuration: holdForDuration == 0 ? nil : holdForDuration,
                  shortcuts: trigger.shortcuts,
                ))
            }
          })

        Toggle(isOn: $leaderKey, label: { Text("Leader Key") })
          .onChange(of: leaderKey, perform: { newValue in
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .keyboardShortcuts(
                KeyboardShortcutTrigger(
                  allowRepeat: allowRepeat,
                  keepLastPartialMatch: keepLastPartialMatch,
                  leaderKey: newValue,
                  passthrough: passthrough,
                  holdDuration: newValue ? nil : holdForDuration,
                  shortcuts: trigger.shortcuts,
                ))
            }
          })
        Spacer()

        HStack {
          Spacer()
          if holdForDuration > 0 {
            Text(trigger.shortcuts.count == 1
              ? "Hold for"
              : "Become modifier after")
          }

          DoubleSlider(
            value: $holdForDuration,
            placeholderText: trigger.shortcuts.count == 1 ? "Add Delay" : "Create Modifier",
            min: 0.08, max: 1.0, step: 0.01, label: {
              Text("Will update all related sequences with matching values.")
            },
          )
          .onChange(of: holdForDuration) { newValue in
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .keyboardShortcuts(
                KeyboardShortcutTrigger(
                  allowRepeat: allowRepeat,
                  keepLastPartialMatch: keepLastPartialMatch,
                  leaderKey: leaderKey,
                  passthrough: passthrough,
                  holdDuration: newValue == 0 ? nil : newValue,
                  shortcuts: trigger.shortcuts,
                ))
            }
          }
          if holdForDuration > 0 {
            Text("seconds")
          }
        }
      }
      .font(.caption)
      .environment(\.toggleStyle, .small)
      .environment(\.toggleFont, .caption)
    }
    .onChange(of: publisher.data, perform: { newValue in
      guard case let .keyboardShortcuts(trigger) = newValue,
            trigger != self.trigger else { return }

      self.trigger = trigger

      holdForDuration = trigger.holdDuration ?? 0
      keepLastPartialMatch = trigger.keepLastPartialMatch
      passthrough = trigger.passthrough
      allowRepeat = trigger.allowRepeat
      leaderKey = trigger.leaderKey
    })
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
        leaderKey: false,
        passthrough: false,
        shortcuts: [
          .empty(),
        ],
      ),
      keyboardShortcutSelectionManager: .init(),
    )
    .designTime()
    .padding()
  }
}

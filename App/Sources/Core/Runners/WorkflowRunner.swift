import Carbon
import Foundation
import MachPort

final class WorkflowRunner: @unchecked Sendable {
  private let commandRunner: CommandRunner
  private let store: KeyCodesStore
  private let notifications: MachPortUINotifications



  init(commandRunner: CommandRunner, store: KeyCodesStore, 
       notifications: MachPortUINotifications) {
    self.commandRunner = commandRunner
    self.store = store
    self.notifications = notifications
  }

  func run(_ workflow: Workflow, for shortcut: KeyShortcut,
           executionOverride: Workflow.Execution? = nil,
           machPortEvent: MachPortEvent, repeatingEvent: Bool) {
    notifications.notifyRunningWorkflow(workflow)
    let commands = workflow.commands.filter(\.isEnabled)

    /// Determines whether the command runner should check for cancellation.
    /// If the workflow is triggered by a keyboard shortcut that is a passthrough and consists of only one shortcut,
    /// and that shortcut is the escape key, then cancellation checking is disabled.
    var checkCancellation: Bool = true
    if let trigger = workflow.trigger,
       case .keyboardShortcuts(let keyboardShortcutTrigger) = trigger,
       keyboardShortcutTrigger.passthrough,
       keyboardShortcutTrigger.shortcuts.count == 1 {
      let shortcut = keyboardShortcutTrigger.shortcuts[0]
      let displayValue = store.displayValue(for: kVK_Escape)
      if shortcut.key == displayValue {
        checkCancellation = false
      }
    }

    let resolveUserEnvironment = workflow.resolveUserEnvironment()
    switch executionOverride ?? workflow.execution {
    case .concurrent:
      commandRunner.concurrentRun(commands, checkCancellation: checkCancellation,
                                  resolveUserEnvironment: resolveUserEnvironment,
                                  shortcut: shortcut, machPortEvent: machPortEvent,
                                  repeatingEvent: repeatingEvent)
    case .serial:
      commandRunner.serialRun(commands, checkCancellation: checkCancellation,
                              resolveUserEnvironment: resolveUserEnvironment,
                              shortcut: shortcut, machPortEvent: machPortEvent,
                              repeatingEvent: repeatingEvent)
    }
  }
}

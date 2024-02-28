import Foundation
import SwiftUI

final class MachPortUINotifications {
  @AppStorage("Notifications.KeyboardCommands") var notificationKeyboardCommands: Bool = false
  @AppStorage("Notifications.RunningWorkflows") var notificationRunningWorkflows: Bool = false
  @AppStorage("Notifications.Bundles") var notificationBundles: Bool = false

  private var shouldReset: Bool = false
  let keyboardShortcutsController: KeyboardShortcutsController

  init(keyboardShortcutsController: KeyboardShortcutsController) {
    self.keyboardShortcutsController = keyboardShortcutsController
  }

  func notifyRunningWorkflow(_ workflow: Workflow) {
    guard notificationRunningWorkflows else { return }
    shouldReset = true
    if case .keyboardShortcuts(let trigger) = workflow.trigger {
      Task { @MainActor in
        WorkflowNotificationController.shared.post(
          WorkflowNotificationViewModel(
            id: workflow.id,
            workflow: workflow,
            keyboardShortcuts: trigger.shortcuts),
          scheduleDismiss: true)
      }
    }
  }

  func notifyKeyboardCommand(_ workflow: Workflow, command: KeyboardCommand) {
    guard notificationKeyboardCommands else { return }
    shouldReset = true
    Task { @MainActor in
      var keyboardShortcuts = [KeyShortcut]()
      if case .keyboardShortcuts(let trigger) = workflow.trigger {
        keyboardShortcuts.append(contentsOf: trigger.shortcuts)
        keyboardShortcuts.append(.init(id: "spacer", key: "="))
        keyboardShortcuts.append(contentsOf: command.keyboardShortcuts)
      }
      WorkflowNotificationController.shared.post(
        WorkflowNotificationViewModel(
          id: workflow.id,
          workflow: nil,
          keyboardShortcuts: keyboardShortcuts),
        scheduleDismiss: true)
    }
  }

  func notifyBundles(_ match: PartialMatch) {
    guard notificationBundles else { return }

    shouldReset = true
    let splits = match.rawValue.split(separator: "+")
    let prefix = splits.count - 1
    if let workflow = match.workflow,
       case .keyboardShortcuts(let trigger) = workflow.trigger {
      let shortcuts = Array(trigger.shortcuts.prefix(prefix))
      let matches = Set(keyboardShortcutsController.allMatchingPrefix(match.rawValue, shortcutIndexPrefix: prefix))

      let sortedMatches = Array(matches)
        .sorted(by: { $0.name < $1.name })

      Task { @MainActor in
        WorkflowNotificationController.shared.cancelReset()
        WorkflowNotificationController.shared.post(
          WorkflowNotificationViewModel(
            id: workflow.id,
            matches: sortedMatches,
            glow: true,
            keyboardShortcuts: shortcuts), 
          scheduleDismiss: false)
      }
    }
  }

  func reset() {
    guard shouldReset else { return }
    shouldReset = false
    Task { @MainActor in
      WorkflowNotificationController.shared.post(
        WorkflowNotificationViewModel(
          id: UUID().uuidString,
          matches: [],
          glow: false,
          keyboardShortcuts: []
        ),
        scheduleDismiss: false
      )
    }
  }

}

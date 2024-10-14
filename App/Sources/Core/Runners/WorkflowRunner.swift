import Carbon
import Foundation
import MachPort

protocol WorkflowRunning {
  func runCommands(in workflow: Workflow)

  func run(_ workflow: Workflow, for shortcut: KeyShortcut,
           executionOverride: Workflow.Execution?,
           machPortEvent: MachPortEvent, repeatingEvent: Bool)
}

final class WorkflowRunner: WorkflowRunning, @unchecked Sendable {
  private let commandRunner: CommandRunner
  private let store: KeyCodesStore
  private let notifications: MachPortUINotifications

  init(commandRunner: CommandRunner, store: KeyCodesStore, 
       notifications: MachPortUINotifications) {
    self.commandRunner = commandRunner
    self.store = store
    self.notifications = notifications
  }

  func runCommands(in workflow: Workflow) {
    let commands = workflow.commands.filter(\.isEnabled)
    guard let machPortEvent = MachPortEvent.empty() else { return }

    switch workflow.execution {
    case .concurrent:
      commandRunner.concurrentRun(
        commands,
        checkCancellation: false,
        resolveUserEnvironment: workflow.resolveUserEnvironment(),
        shortcut: .empty(),
        machPortEvent: machPortEvent,
        repeatingEvent: false
      )
    case .serial:
      commandRunner.serialRun(
        commands,
        checkCancellation: true,
        resolveUserEnvironment: workflow.resolveUserEnvironment(),
        shortcut: .empty(),
        machPortEvent: machPortEvent,
        repeatingEvent: false
      )
    }
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

    guard workflow.isValidForRepeatWorkflowCommand else {
      return
    }

    if commandRunner.runners.builtIn.repeatLastWorkflowRunner.workflowRunner == nil {
      commandRunner.runners.builtIn.repeatLastWorkflowRunner.workflowRunner = self
    }

    Task { @MainActor in
      RepeatLastWorkflowRunner.previousWorkflow = workflow
    }
  }
}

private extension Workflow {
  var isValidForRepeatWorkflowCommand: Bool {
    commands.allSatisfy { command in
      switch command {
        case .application:                           return true
        case .builtIn:                               return false
        case .bundled:                               return false
        case .keyboard:                              return true
        case .mouse:                                 return true
        case .menuBar:                               return true
        case .open:                                  return true
        case .shortcut:                              return true
        case .script:                                return true
        case .text:                                  return true
        case .systemCommand(let systemCommand):
          switch systemCommand.kind {
            case .activateLastApplication:           return true
            case .applicationWindows:                return false
            case .hideAllApps:                       return false
            case .minimizeAllOpenWindows:            return false
            case .missionControl:                    return false
            case .moveFocusToNextWindowUpperLeftQuarter: return false
            case .moveFocusToNextWindowUpperRightQuarter: return false
            case .moveFocusToNextWindowLowerLeftQuarter: return false
            case .moveFocusToNextWindowLowerRightQuarter: return false
            case .moveFocusToNextWindowOnLeft:        return false
            case .moveFocusToNextWindowOnRight:       return false
            case .moveFocusToNextWindowUpwards:       return false
            case .moveFocusToNextWindowDownwards:     return false
            case .moveFocusToNextWindowFront:         return false
            case .moveFocusToNextWindowCenter:        return false
            case .moveFocusToPreviousWindowFront:     return false
            case .moveFocusToNextWindow:              return false
            case .moveFocusToPreviousWindow:          return false
            case .moveFocusToNextWindowGlobal:        return false
            case .moveFocusToPreviousWindowGlobal:    return false
            case .showDesktop:                        return false
            case .windowTilingLeft:                   return true
            case .windowTilingRight:                  return true
            case .windowTilingTop:                    return true
            case .windowTilingBottom:                 return true
            case .windowTilingTopLeft:                return true
            case .windowTilingTopRight:               return true
            case .windowTilingBottomLeft:             return true
            case .windowTilingBottomRight:            return true
            case .windowTilingCenter:                 return true
            case .windowTilingFill:                   return true
            case .windowTilingZoom:                   return true
            case .windowTilingArrangeLeftRight:       return true
            case .windowTilingArrangeRightLeft:       return true
            case .windowTilingArrangeTopBottom:       return true
            case .windowTilingArrangeBottomTop:       return true
            case .windowTilingArrangeLeftQuarters:    return true
            case .windowTilingArrangeRightQuarters:   return true
            case .windowTilingArrangeTopQuarters:     return true
            case .windowTilingArrangeBottomQuarters:  return true
            case .windowTilingArrangeDynamicQuarters: return true
            case .windowTilingArrangeQuarters:        return true
            case .windowTilingPreviousSize:           return true
          }
        case .uiElement:                             return true
        case .windowManagement(let command):
        switch command.kind {
        case .increaseSize: return false
        case .decreaseSize: return false
        case .move: return false
        case .fullscreen: return false
        case .center: return false
        case .moveToNextDisplay: return true
        case .anchor: return false
        }
      }
    }
  }
}

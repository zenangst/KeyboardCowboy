import Carbon
import Foundation
import MachPort

protocol WorkflowRunning {
  func runCommands(in workflow: Workflow)

  func run(_ workflow: Workflow, executionOverride: Workflow.Execution?,
           machPortEvent: MachPortEvent, repeatingEvent: Bool) async
}

final class WorkflowRunner: WorkflowRunning, Sendable {
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
    let commands = workflow.machPortConditions.enabledCommands
    guard let machPortEvent = MachPortEvent.empty() else { return }

    switch workflow.execution {
    case .concurrent:
      commandRunner.concurrentRun(
        commands,
        checkCancellation: false,
        resolveUserEnvironment: workflow.resolveUserEnvironment(),
        machPortEvent: machPortEvent,
        repeatingEvent: false,
      )
    case .serial:
      commandRunner.serialRun(
        commands,
        checkCancellation: true,
        resolveUserEnvironment: workflow.resolveUserEnvironment(),
        machPortEvent: machPortEvent,
        repeatingEvent: false,
      )
    }
  }

  func run(_ workflow: Workflow, executionOverride: Workflow.Execution? = nil,
           machPortEvent: MachPortEvent, repeatingEvent: Bool) async {
    Task.detached { @MainActor [weak notifications] in
      notifications?.notifyRunningWorkflow(workflow)
    }
    let commands = workflow.machPortConditions.enabledCommands

    /// Determines whether the command runner should check for cancellation.
    /// If the workflow is triggered by a keyboard shortcut that is a passthrough and consists of only one shortcut,
    /// and that shortcut is the escape key, then cancellation checking is disabled.
    var checkCancellation = true
    if let trigger = workflow.trigger,
       case let .keyboardShortcuts(keyboardShortcutTrigger) = trigger,
       keyboardShortcutTrigger.passthrough,
       keyboardShortcutTrigger.shortcuts.count == 1 {
      let shortcut = keyboardShortcutTrigger.shortcuts[0]
      let displayValue = await store.displayValue(for: kVK_Escape)
      if shortcut.key == displayValue {
        checkCancellation = false
      }
    }

    let resolveUserEnvironment = workflow.resolveUserEnvironment()
    switch executionOverride ?? workflow.execution {
    case .concurrent:
      commandRunner.concurrentRun(commands, checkCancellation: checkCancellation,
                                  resolveUserEnvironment: resolveUserEnvironment,
                                  machPortEvent: machPortEvent, repeatingEvent: repeatingEvent)
    case .serial:
      commandRunner.serialRun(commands, checkCancellation: checkCancellation,
                              resolveUserEnvironment: resolveUserEnvironment,
                              machPortEvent: machPortEvent, repeatingEvent: repeatingEvent)
    }

    guard workflow.isValidForRepeatWorkflowCommand else {
      return
    }

    if await commandRunner.runners.builtIn.repeatLastWorkflowRunner.workflowRunner == nil {
      await commandRunner.runners.builtIn.repeatLastWorkflowRunner.setWorkflowRunner(self)
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
      case .application: true
      case .builtIn: false
      case .bundled: false
      case .keyboard: true
      case .mouse: true
      case .menuBar: true
      case .open: true
      case .shortcut: true
      case .script: true
      case .text: true
      case let .systemCommand(systemCommand):
        switch systemCommand.kind {
        case .showNotificationCenter: false
        case .activateLastApplication: true
        case .applicationWindows: false
        case .hideAllApps: false
        case .fillAllOpenWindows: false
        case .minimizeAllOpenWindows: false
        case .missionControl: false
        case .showDesktop: false
        }
      case .uiElement: true
      case .windowFocus: false
      case .windowTiling: true
      case let .windowManagement(command):
        switch command.kind {
        case .increaseSize: false
        case .decreaseSize: false
        case .move: false
        case .fullscreen: false
        case .center: false
        case .moveToNextDisplay: true
        case .anchor: false
        }
      }
    }
  }
}

import Carbon.HIToolbox
import Cocoa
import Combine
import Foundation
import MachPort
import InputSources
import KeyCodes
import os

final class MachPortCoordinator: @unchecked Sendable, ObservableObject {
  @Published private(set) var event: MachPortEvent?
  @MainActor @Published private(set) var coordinatorEvent: CGEvent?
  @Published private(set) var flagsChanged: CGEventFlags?
  @Published private(set) var recording: KeyShortcutRecording?
  @Published private(set) var mode: KeyboardCowboyMode

  @MainActor var machPort: MachPortEventController? {
    didSet {
      keyboardCommandRunner.machPort = machPort
      scheduledMachPortCoordinator.machPort = machPort
    }
  }

  private static let defaultPartialMatch: PartialMatch = .init(rawValue: ".")

  private var flagsChangedSubscription: AnyCancellable?
  private var keyboardCowboyModeSubscription: AnyCancellable?
  private var machPortEventSubscription: AnyCancellable?
  private var previousPartialMatch: PartialMatch = .init(rawValue: ".")
  private var previousExactMatch: Workflow?
  private var repeatingKeyCode: Int64 = -1
  private var repeatingResult: ((MachPortEvent, Bool) -> Void)?
  private var repeatingMatch: Bool?
  private var shouldHandleKeyUp: Bool = false
  private var specialKeys: [Int] = [Int]()
  private var scheduledWorkItem: DispatchWorkItem?
  private var capsLockDown: Bool = false
  private var scheduledAction: ScheduleMachPortCoordinator.ScheduledAction?

  private let keyboardCleaner: KeyboardCleaner
  private let keyboardCommandRunner: KeyboardCommandRunner
  private let keyboardShortcutsController: KeyboardShortcutsController
  private let macroCoordinator: MacroCoordinator
  private let notifications: MachPortUINotifications
  private let scheduledMachPortCoordinator: ScheduleMachPortCoordinator
  private let recordValidator: MachPortRecordValidator
  private let store: KeyCodesStore
  private let workflowRunner: WorkflowRunner

  internal init(store: KeyCodesStore,
                keyboardCleaner: KeyboardCleaner,
                keyboardCommandRunner: KeyboardCommandRunner,
                keyboardShortcutsController: KeyboardShortcutsController,
                macroCoordinator: MacroCoordinator,
                mode: KeyboardCowboyMode,
                notifications: MachPortUINotifications,
                workflowRunner: WorkflowRunner) {
    self.keyboardCleaner = keyboardCleaner
    self.macroCoordinator = macroCoordinator
    self.store = store
    self.keyboardShortcutsController = keyboardShortcutsController
    self.keyboardCommandRunner = keyboardCommandRunner
    self.notifications = notifications
    self.mode = mode
    self.specialKeys = Array(store.specialKeys().keys)
    self.workflowRunner = workflowRunner
    self.recordValidator = MachPortRecordValidator(store: store)
    self.scheduledMachPortCoordinator = ScheduleMachPortCoordinator(defaultPartialMatch: Self.defaultPartialMatch)
  }

  func captureUIElement() {
    mode = .captureUIElement
  }

  func stopCapturingUIElement() {
    mode = .intercept
  }

  func subscribe(to publisher: Published<KeyboardCowboyMode?>.Publisher) {
    keyboardCowboyModeSubscription = publisher
      .compactMap({ $0 })
      .sink { [weak self] mode in
        guard let self else { return }
        self.mode = mode
        self.specialKeys = Array(self.store.specialKeys().keys)
      }
  }

  @MainActor
  func receiveEvent(_ machPortEvent: MachPortEvent) {
    switch mode {
    case .disabled: return
    case .captureUIElement: break
    case .intercept, .recordMacro:
      guard machPortEvent.type != .leftMouseUp &&
            machPortEvent.type != .leftMouseDown &&
            machPortEvent.type != .leftMouseDragged else {
        return
      }

      intercept(machPortEvent, runningMacro: false)
    case .recordKeystroke:
      record(machPortEvent)
    }

    self.event = machPortEvent
  }

  func receiveFlagsChanged(_ machPortEvent: MachPortEvent) {
    let flags = machPortEvent.event.flags
    scheduledWorkItem?.cancel()
    scheduledWorkItem = nil
    flagsChanged = flags
    capsLockDown = machPortEvent.keyCode == kVK_CapsLock
    repeatingResult = nil
    repeatingMatch = nil
    repeatingKeyCode = -1
  }
 
  // MARK: - Private methods

  @MainActor
  private func intercept(_ machPortEvent: MachPortEvent, tryGlobals: Bool = false, runningMacro: Bool) {
    if keyboardCleaner.isEnabled, keyboardCleaner.consumeEvent(machPortEvent) {
      return
    }

    if launchArguments.isEnabled(.disableMachPorts) { return }

    let machPortKeyCode = Int(machPortEvent.keyCode)
    let isRepeatingEvent: Bool = machPortEvent.event.getIntegerValueField(.keyboardEventAutorepeat) == 1

    switch machPortEvent.type {
    case .keyDown:
      switch scheduledAction {
      case .captureKeyDown(let keyCode):
        if keyCode == machPortKeyCode {
          machPortEvent.result = nil
          return
        }
      case .none: break
      }
      let shouldReturn = handleEscapeKeyDownEvent(machPortEvent)
      if shouldReturn { return }
    case .keyUp:
      switch scheduledAction {
      case .captureKeyDown(let keyCode):
        if keyCode == machPortKeyCode {
          scheduledAction = nil
          _ = try? machPort?.post(machPortKeyCode, type: .keyDown, flags: machPortEvent.event.flags)
          _ = try? machPort?.post(machPortKeyCode, type: .keyUp, flags: machPortEvent.event.flags)
          previousPartialMatch = Self.defaultPartialMatch
          return
        }
      case .none: break
      }

      scheduledMachPortCoordinator.cancel()
      handleKeyUp(machPortEvent)
      scheduledWorkItem?.cancel()
      scheduledWorkItem = nil
      repeatingResult = nil
      repeatingMatch = nil
      return
    default:
      return
    }

    if handleRepeatingKeyEvent(machPortEvent, isRepeatingEvent: isRepeatingEvent) { return }

    guard let shortcut = MachPortKeyboardShortcut(machPortEvent, specialKeys: specialKeys, store: store) else {
      return
    }

    var keyboardShortcut: KeyShortcut = shortcut.original

    if handleMacroExecution(machPortEvent, shortcut: shortcut, keyboardShortcut: &keyboardShortcut) { return }

    let bundleIdentifier = UserSpace.shared.frontMostApplication.bundleIdentifier

    // Found a match
    let userModes = UserSpace.shared.userModes.filter(\.isEnabled)
    var result = keyboardShortcutsController.lookup(shortcut.original, bundleIdentifier: bundleIdentifier,
                                                    userModes: userModes, partialMatch: previousPartialMatch
    )

    if result == nil {
      result = keyboardShortcutsController.lookup(shortcut.uppercase, bundleIdentifier: bundleIdentifier,
                                                  userModes: userModes, partialMatch: previousPartialMatch)
      keyboardShortcut = shortcut.uppercase
      // Workaround for the mismatch that can occur when the user tries to type
      // a sequence that involves conflicting positions for the modifier keys.
      // When done in quick succession, the `flagsChanged` event will report
      // the the first modifier keys position based on the keycode, which is
      // not always accurate. This workaround disables left-hand-side conditions
      // for workflows that use keyboard shortcut sequences.
      if previousPartialMatch.rawValue != Self.defaultPartialMatch.rawValue && result == nil {
        result = keyboardShortcutsController.lookup(shortcut.lhsAgnostic, bundleIdentifier: bundleIdentifier,
                                                    userModes: userModes, partialMatch: previousPartialMatch)
        keyboardShortcut = shortcut.lhsAgnostic
      }
    }

    scheduledAction = nil
    switch result {
    case .partialMatch(let partialMatch):
      handlePartialMatch(partialMatch, machPortEvent: machPortEvent, shortcut: shortcut)
    case .exact(let workflow):
      previousExactMatch = workflow
      previousPartialMatch = Self.defaultPartialMatch
      handleExtactMatch(workflow, machPortEvent: machPortEvent,
                        shortcut: shortcut, isRepeatingEvent: isRepeatingEvent)
    case .none:
      handleNoMatch(result, machPortEvent: machPortEvent,
                    shortcut: shortcut, isRepeatingEvent: isRepeatingEvent,
                    tryGlobals: tryGlobals, runningMacro: runningMacro)
    }
  }

  private func handlePartialMatch(_ partialMatch: PartialMatch, machPortEvent: MachPortEvent, shortcut: MachPortKeyboardShortcut) {
    let onTask: @Sendable (ScheduleMachPortCoordinator.ScheduledAction?) -> Void = { [weak self] action in
      guard let self else { return }
      switch action {
      case .captureKeyDown:
        self.previousPartialMatch = partialMatch
      default:
        self.previousPartialMatch = Self.defaultPartialMatch
      }
      self.scheduledAction = action
    }

    scheduledAction = nil
    if scheduledMachPortCoordinator.handlePartialMatchIfApplicable(partialMatch,
                                                                   machPortEvent: machPortEvent,
                                                                   onTask: onTask) {
      repeatingMatch = nil
      machPortEvent.result = nil
    } else if let workflow = partialMatch.workflow,
              case .keyboardShortcuts(let keyboardShortcut) = workflow.trigger,
              keyboardShortcut.passthrough,
              macroCoordinator.state == .recording && machPortEvent.type == .keyDown {
      macroCoordinator.record(shortcut, kind: .event(machPortEvent), machPortEvent: machPortEvent)
      previousPartialMatch = partialMatch
    } else {
      machPortEvent.result = nil
      previousPartialMatch = partialMatch
    }

    if machPortEvent.type == .keyDown {
      notifications.notifyBundles(partialMatch)
    }
  }

  @MainActor
  private func handleExtactMatch(_ workflow: Workflow, machPortEvent: MachPortEvent,
                                 shortcut: MachPortKeyboardShortcut, isRepeatingEvent: Bool) {
    if workflow.trigger.isPassthrough == true {
      // NOOP
    } else {
      machPortEvent.result = nil
    }

    let enabledCommands = workflow.commands.filter(\.isEnabled)
    let execution: @MainActor @Sendable (MachPortEvent, Bool) -> Void

    // Handle keyboard commands early to avoid cancelling previous keyboard invocations.
    if enabledCommands.count == 1,
       case .keyboard(let command) = enabledCommands.first {

      guard machPortEvent.event.type == .keyDown else { return }

      if !isRepeatingEvent {
        notifications.notifyKeyboardCommand(workflow, command: command)
      }

      execution = { [weak self, keyboardCommandRunner] machPortEvent, _ in
        guard let self else { return }
        guard let newEvents = try? keyboardCommandRunner.run(command.keyboardShortcuts,
                                                             originalEvent: machPortEvent.event,
                                                             iterations: command.iterations,
                                                             with: machPortEvent.eventSource) else {
          return
        }

        for newEvent in newEvents {
          self.coordinatorEvent = newEvent
        }
      }

      if macroCoordinator.state == .recording {
        macroCoordinator.record(shortcut, kind: .workflow(workflow), machPortEvent: machPortEvent)
      }

      Task.detached { await execution(machPortEvent, isRepeatingEvent) }

      repeatingResult = execution
      repeatingKeyCode = machPortEvent.keyCode
      notifications.reset()
    } else if !workflow.commands.isEmpty && workflow.commands.isValidForRepeat {
      guard machPortEvent.type == .keyDown else { return }
      if macroCoordinator.state == .recording {
        macroCoordinator.record(shortcut, kind: .workflow(workflow), machPortEvent: machPortEvent)
      }
      execution = { [workflowRunner, weak self] machPortEvent, repeatingEvent in
        guard let self, machPortEvent.type != .keyUp else { return }
        self.coordinatorEvent = machPortEvent.event
        workflowRunner.run(workflow, for: shortcut.original, machPortEvent: machPortEvent, repeatingEvent: repeatingEvent)
      }

      Task.detached { await execution(machPortEvent, isRepeatingEvent) }

      repeatingResult = execution
      repeatingKeyCode = machPortEvent.keyCode
    } else if workflow.commands.allSatisfy({
      if case .systemCommand = $0 { return true } else { return false }
    }) {
      if machPortEvent.type == .keyDown && isRepeatingEvent {
        shouldHandleKeyUp = true
        return
      }

      if machPortEvent.type == .keyUp {
        if shouldHandleKeyUp {
          shouldHandleKeyUp = false
          coordinatorEvent = machPortEvent.event
        } else {
          return
        }
      }

      if macroCoordinator.state == .recording && machPortEvent.type == .keyDown {
        macroCoordinator.record(shortcut, kind: .workflow(workflow), machPortEvent: machPortEvent)
      }

      if let delay = shouldSchedule(workflow) {
        scheduledWorkItem = schedule(workflow, for: shortcut.original, machPortEvent: machPortEvent, after: delay)
      } else {
        workflowRunner.run(workflow, for: shortcut.original, machPortEvent: machPortEvent, repeatingEvent: false)
      }
    } else if machPortEvent.type == .keyDown, !isRepeatingEvent {
      if macroCoordinator.state == .recording {
        macroCoordinator.record(shortcut, kind: .workflow(workflow), machPortEvent: machPortEvent)
      }

      if let delay = shouldSchedule(workflow) {
        scheduledWorkItem = schedule(workflow, for: shortcut.original, machPortEvent: machPortEvent, after: delay)
      } else {
        workflowRunner.run(workflow, for: shortcut.original, machPortEvent: machPortEvent, repeatingEvent: false)
      }
    }
  }

  @MainActor
  private func handleNoMatch(_ result: KeyboardShortcutResult?, machPortEvent: MachPortEvent,
                             shortcut: MachPortKeyboardShortcut, isRepeatingEvent: Bool,
                             tryGlobals: Bool, runningMacro: Bool) {
    guard machPortEvent.type == .keyDown else { return }

    // No match, reset the lookup key
    reset()

    // Disable caps lock.
    // TODO: Add a setting for this!
    //        var newFlags = machPortEvent.event.flags
    //        newFlags.subtract(.maskAlphaShift)
    //        machPortEvent.event.flags = newFlags
    if !tryGlobals {
      intercept(machPortEvent, tryGlobals: true, runningMacro: runningMacro)
      repeatingMatch = false
    } else {
      coordinatorEvent = machPortEvent.event
      if macroCoordinator.state == .recording {
        macroCoordinator.record(shortcut, kind: .event(machPortEvent), machPortEvent: machPortEvent)
      }
    }
  }

  private func record(_ machPortEvent: MachPortEvent) {
    machPortEvent.result = nil
    mode = .intercept
    recording = recordValidator.validate(machPortEvent, allowAllKeys: true)
  }

  private func reset(_ function: StaticString = #function, line: Int = #line) {
    previousPartialMatch = Self.defaultPartialMatch
    notifications.reset()
  }

  /// Handles the Escape key down event.
  ///
  /// - Parameter machPortEvent: The MachPortEvent representing the key event.
  /// - Returns: A Boolean value indicating whether the execution should return early (true) or continue (false).
  private func handleEscapeKeyDownEvent(_ machPortEvent: MachPortEvent) -> Bool {
    if machPortEvent.keyCode == kVK_Escape {
      notifications.reset()
      if previousPartialMatch.rawValue != Self.defaultPartialMatch.rawValue, machPortEvent.event.flags == CGEventFlags.maskNonCoalesced {
        machPortEvent.result = nil
        reset()
        return true
      }
    }
    return false
  }

  /// Handles the key up event.
  ///
  /// - Parameter machPortEvent: The MachPortEvent representing the key event.
  private func handleKeyUp(_ machPortEvent: MachPortEvent) {
    if let repeatingResult {
      repeatingResult(machPortEvent, false)

      if let previousExactMatch, previousExactMatch.trigger.isPassthrough == true {
        self.previousExactMatch = nil
      } else if previousPartialMatch.workflow?.trigger.isPassthrough == true {
      } else {
        machPortEvent.result = nil
      }
    }
  }

  /// Handles repeating key events.
  ///
  /// - Parameters:
  ///   - machPortEvent: The MachPortEvent representing the key event.
  ///   - isRepeatingEvent: A Boolean value indicating whether the event is a repeating event.
  /// - Returns: A Boolean value indicating whether the execution should return early (true) or continue (false).
  private func handleRepeatingKeyEvent(_ machPortEvent: MachPortEvent, isRepeatingEvent: Bool) -> Bool {
    // If the event is repeating and there is an earlier result,
    // reuse that result to avoid unnecessary lookups.
    if isRepeatingEvent, let repeatingResult, repeatingKeyCode == machPortEvent.keyCode {
      machPortEvent.result = nil
      repeatingResult(machPortEvent, true)
      return true
      // If the event is repeating and there is no earlier result,
      // simply opt-out because we don't want to lookup the same
      // keyboard shortcut over and over again.
    } else if isRepeatingEvent, repeatingMatch == false {
      return true
      // Reset the repeating result and match if the event is not repeating.
    } else {
      repeatingResult = nil
      repeatingMatch = nil
      repeatingKeyCode = -1
      return false
    }
  }

  @MainActor
  func handleMacroExecution(_ machPortEvent: MachPortEvent, shortcut: MachPortKeyboardShortcut, keyboardShortcut: inout KeyShortcut) -> Bool {
    guard machPortEvent.type == .keyDown else { return false }

    // If there is a match, then run the workflow
    let readyToRunMacro = mode == .intercept && macroCoordinator.state == .idle
    if readyToRunMacro, let macro = macroCoordinator.match(shortcut) {
      let keyboardShortcutCopy: KeyShortcut = keyboardShortcut
      let iterations = max(Int(SnippetController.currentSnippet) ?? 1, 1)

      Task.detached { [machPort, workflowRunner, keyboardCommandRunner] in
        for _  in 0..<iterations {
          let specialKeys: [Int] = [kVK_Return]

          for element in macro {
            switch element {
            case .event(let machPortEvent):
              let keyCode = Int(machPortEvent.keyCode)

              if specialKeys.contains(keyCode) { try await Task.sleep(for: .milliseconds(150)) }

              try machPort?.post(keyCode, type: .keyDown, flags: machPortEvent.event.flags)
              try machPort?.post(keyCode, type: .keyUp, flags: machPortEvent.event.flags)
            case .workflow(let workflow):
              if workflow.commands.allSatisfy({ $0.isKeyboardBinding }) {
                for command in workflow.commands {
                  if case .keyboard(let command) = command {
                    _ = try keyboardCommandRunner.run(command.keyboardShortcuts,
                                                      originalEvent: nil,
                                                      iterations: command.iterations,
                                                      isRepeating: false,
                                                      with: machPortEvent.eventSource)
                  }
                }
              } else {
                workflowRunner.run(workflow, for: keyboardShortcutCopy,
                                   executionOverride: .serial,
                                   machPortEvent: machPortEvent, repeatingEvent: false)
              }
            }
          }
        }
      }

      SnippetController.currentSnippet = ""
      machPortEvent.result = nil
      return true
    } else if macroCoordinator.state == .removing {
      macroCoordinator.remove(shortcut, machPortEvent: machPortEvent)
      return true
    } else {
      return false
    }
  }

  private func schedule(_ workflow: Workflow, for shortcut: KeyShortcut, 
                        machPortEvent: MachPortEvent, after duration: Double) -> DispatchWorkItem {
    let workItem = DispatchWorkItem { [weak self] in
      guard let self else { return }
      guard self.scheduledWorkItem?.isCancelled != true else { return }

      workflowRunner.run(workflow, for: shortcut, machPortEvent: machPortEvent, repeatingEvent: false)
      reset()
      previousPartialMatch = Self.defaultPartialMatch
      self.scheduledWorkItem = nil
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)

    return workItem
  }

  private func shouldSchedule(_ workflow: Workflow) -> Double? {
    if case .keyboardShortcuts(let trigger) = workflow.trigger, let holdDuration = trigger.holdDuration, trigger.shortcuts.count == 1,
       holdDuration > 0 {
      return holdDuration
    } else {
      return nil
    }
  }
}

private extension Collection where Element == Command {
  var isValidForRepeat: Bool {
    allSatisfy { element in
      switch element {
      case .keyboard, .menuBar, .windowManagement: true
      case .systemCommand(let command):
        switch command.kind {
        case .moveFocusToNextWindowUpwards:   true
        case .moveFocusToNextWindowOnLeft:    true
        case .moveFocusToNextWindowOnRight:   true
        case .moveFocusToNextWindowDownwards: true
        default:
          false
        }
      default: false
      }
    }
  }
}


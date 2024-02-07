import Carbon.HIToolbox
import Cocoa
import Combine
import Foundation
import MachPort
import InputSources
import KeyCodes
import os

final class MachPortCoordinator {
  enum RestrictedKeyCode: Int, CaseIterable {
    case backspace = 117
    case delete = 51
    case enter = 36
    case escape = 53
  }

  @Published private(set) var event: MachPortEvent?
  @Published private(set) var flagsChanged: CGEventFlags?
  @Published private(set) var recording: KeyShortcutRecording?
  @Published private(set) var mode: KeyboardCowboyMode

  var machPort: MachPortEventController? {
    didSet { keyboardCommandRunner.machPort = machPort }
  }

  private static let defaultPartialMatch: PartialMatch = .init(rawValue: ".")

  private var flagsChangedSubscription: AnyCancellable?
  private var keyboardCowboyModeSubscription: AnyCancellable?
  private var machPortEventSubscription: AnyCancellable?
  private var previousPartialMatch: PartialMatch = .init(rawValue: ".")
  private var repeatingKeyCode: Int64 = -1
  private var repeatingResult: ((MachPortEvent, Bool) -> Void)?
  private var repeatingMatch: Bool?
  private var shouldHandleKeyUp: Bool = false
  private var specialKeys: [Int] = [Int]()
  private var workItem: DispatchWorkItem?
  private var capsLockDown: Bool = false

  private let commandRunner: CommandRunner
  private let keyboardCommandRunner: KeyboardCommandRunner
  private let keyboardShortcutsController: KeyboardShortcutsController
  private let notifications: MachPortUINotifications
  private let store: KeyCodesStore

  internal init(store: KeyCodesStore,
                commandRunner: CommandRunner,
                keyboardCommandRunner: KeyboardCommandRunner,
                keyboardShortcutsController: KeyboardShortcutsController,
                mode: KeyboardCowboyMode) {
    self.commandRunner = commandRunner
    self.store = store
    self.keyboardShortcutsController = keyboardShortcutsController
    self.keyboardCommandRunner = keyboardCommandRunner
    self.notifications = MachPortUINotifications(keyboardShortcutsController: keyboardShortcutsController)
    self.mode = mode
    self.specialKeys = Array(store.specialKeys().keys)
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

  func receiveEvent(_ machPortEvent: MachPortEvent) {
    switch mode {
    case .disabled: break
    case .captureUIElement:
      self.event = machPortEvent
    case .intercept:
      guard machPortEvent.type != .leftMouseUp &&
            machPortEvent.type != .leftMouseDown &&
            machPortEvent.type != .leftMouseDragged else {
        return
      }

      intercept(machPortEvent)
      self.event = machPortEvent
    case .recordKeystroke:
      record(machPortEvent)
      self.event = machPortEvent
    }
  }

  func receiveFlagsChanged(_ machPortEvent: MachPortEvent) {
    let flags = machPortEvent.event.flags
    self.workItem?.cancel()
    self.workItem = nil
    self.flagsChanged = flags
    self.capsLockDown = machPortEvent.keyCode == kVK_CapsLock
    self.repeatingResult = nil
    self.repeatingMatch = nil
    self.repeatingKeyCode = -1
  }
 
  // MARK: - Private methods

  private func intercept(_ machPortEvent: MachPortEvent, tryGlobals: Bool = false) {
    if launchArguments.isEnabled(.disableMachPorts) { return }

    let isRepeatingEvent: Bool = machPortEvent.event.getIntegerValueField(.keyboardEventAutorepeat) == 1
    switch machPortEvent.type {
    case .keyDown:
      if previousPartialMatch.rawValue != Self.defaultPartialMatch.rawValue,
         machPortEvent.keyCode == kVK_Escape {
        if machPortEvent.event.flags == CGEventFlags.maskNonCoalesced {
          machPortEvent.result = nil
          reset()
          return
        }
      }
    case .keyUp:
      workItem?.cancel()
      workItem = nil
      repeatingResult = nil
      repeatingMatch = nil
    default:
      return
    }

    // If the event is repeating and there is an earlier result,
    // reuse that result to avoid unnecessary lookups.
    if isRepeatingEvent, let repeatingResult, repeatingKeyCode == machPortEvent.keyCode {
      machPortEvent.result = nil
      repeatingResult(machPortEvent, true)
      return
    // If the event is repeating and there is no earlier result,
    // simply opt-out because we don't want to lookup the same
    // keyboard shortcut over and over again.
    } else if isRepeatingEvent, repeatingMatch == false {
      return
    // Reset the repeating result and match if the event is not repeating.
    } else {
      repeatingResult = nil
      repeatingMatch = nil
      repeatingKeyCode = -1
    }

    guard let displayValue = store.displayValue(for: Int(machPortEvent.keyCode)) else {
      return
    }

    let modifiers = VirtualModifierKey.fromCGEvent(machPortEvent.event, specialKeys: specialKeys)
      .compactMap({ ModifierKey(rawValue: $0.rawValue) })

    let keyboardShortcut = KeyShortcut(
      id: UUID().uuidString,
      key: displayValue,
      lhs: machPortEvent.lhs,
      modifiers: modifiers
    )

    // Found a match
    let userModes = UserSpace.shared.userModes.filter(\.isEnabled)
    var result = keyboardShortcutsController.lookup(
      keyboardShortcut,
      bundleIdentifier: UserSpace.shared.frontMostApplication.bundleIdentifier,
      userModes: userModes,
      partialMatch: previousPartialMatch
    )
    if result == nil {
      result = keyboardShortcutsController.lookup(
        KeyShortcut(key: displayValue.uppercased(), lhs: machPortEvent.lhs, modifiers: modifiers),
        bundleIdentifier: UserSpace.shared.frontMostApplication.bundleIdentifier,
        userModes: userModes,
        partialMatch: previousPartialMatch
      )

      // Workaround for the mismatch that can occur when the user tries to type
      // a sequence that involves conflicting positions for the modifier keys.
      // When done in quick succession, the `flagsChanged` event will report
      // the the first modifier keys position based on the keycode, which is
      // not always accurate. This workaround disables left-hand-side conditions
      // for workflows that use keyboard shortcut sequences.
      if previousPartialMatch.rawValue != Self.defaultPartialMatch.rawValue && result == nil {
        result = keyboardShortcutsController.lookup(
          KeyShortcut(key: displayValue, lhs: false, modifiers: modifiers),
          bundleIdentifier: UserSpace.shared.frontMostApplication.bundleIdentifier,
          userModes: userModes,
          partialMatch: previousPartialMatch
        )
      }
    }

    process(result,
            machPortEvent: machPortEvent,
            isRepeatingEvent: isRepeatingEvent,
            tryGlobals: tryGlobals)
  }

  private func process(_ result: KeyboardShortcutResult?, 
                       machPortEvent: MachPortEvent,
                       isRepeatingEvent: Bool,
                       tryGlobals: Bool) {
    switch result {
    case .partialMatch(let partialMatch):
      if let workflow = partialMatch.workflow,
         workflow.trigger?.isPassthrough == true {
        // NOOP
      } else {
        machPortEvent.result = nil
      }

      if machPortEvent.type == .keyDown {
        notifications.notifyBundles(partialMatch)
        previousPartialMatch = partialMatch
      }
    case .exact(let workflow):
      if workflow.trigger?.isPassthrough == true {
        // NOOP
      } else {
        machPortEvent.result = nil
      }

      let enabledWorkflows = workflow.commands.filter(\.isEnabled)
      let execution: (MachPortEvent, Bool) -> Void

      if enabledWorkflows.count == 1,
         case .keyboard(let command) = enabledWorkflows.first {
        if !isRepeatingEvent && machPortEvent.event.type == .keyDown {
          notifications.notifyKeyboardCommand(workflow, command: command)
        }

        execution = { [keyboardCommandRunner] machPortEvent, _ in
          try? keyboardCommandRunner.run(command.keyboardShortcuts,
                                         type: machPortEvent.type,
                                         originalEvent: machPortEvent.event,
                                         with: machPortEvent.eventSource)
        }
        execution(machPortEvent, isRepeatingEvent)
        repeatingResult = execution
        repeatingKeyCode = machPortEvent.keyCode
        previousPartialMatch = Self.defaultPartialMatch
      } else if workflow.commands.isValidForRepeat {
        guard machPortEvent.type == .keyDown else { return }
        execution = { [weak self] machPortEvent, repeatingEvent in
          self?.run(workflow, repeatingEvent: repeatingEvent)
        }
        execution(machPortEvent, isRepeatingEvent)
        repeatingResult = execution
        repeatingKeyCode = machPortEvent.keyCode
        previousPartialMatch = Self.defaultPartialMatch
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
          } else {
            return
          }
        }

        if let delay = shouldSchedule(workflow) {
          workItem = schedule(workflow, after: delay)
        } else {
          run(workflow, repeatingEvent: false)
        }
      } else if machPortEvent.type == .keyDown, !isRepeatingEvent {
        if let delay = shouldSchedule(workflow) {
          workItem = schedule(workflow, after: delay)
        } else {
          run(workflow, repeatingEvent: false)
        }

        previousPartialMatch = Self.defaultPartialMatch
      }
    case .none:
      if machPortEvent.type == .keyDown {
        // No match, reset the lookup key
        reset()

        // Disable caps lock.
        // TODO: Add a setting for this!
//        var newFlags = machPortEvent.event.flags
//        newFlags.subtract(.maskAlphaShift)
//        machPortEvent.event.flags = newFlags

        if !tryGlobals {
          intercept(machPortEvent, tryGlobals: true)
          repeatingMatch = false
        }
      }
    }
  }

  private func record(_ machPortEvent: MachPortEvent) {
    machPortEvent.result = nil
    self.mode = .intercept
    self.recording = validate(machPortEvent, allowAllKeys: true)
  }

  private func validate(_ machPortEvent: MachPortEvent, allowAllKeys: Bool = false) -> KeyShortcutRecording {
    let keyCode = Int(machPortEvent.keyCode)

    guard let displayValue = store.displayValue(for: keyCode) else {
      return .cancel(.empty())
    }

    let virtualModifiers = VirtualModifierKey
      .fromCGEvent(machPortEvent.event,
                   specialKeys: Array(store.specialKeys().keys))
    let modifiers = virtualModifiers
      .compactMap({ ModifierKey(rawValue: $0.rawValue) })
    let keyboardShortcut = KeyShortcut(
      id: UUID().uuidString,
      key: displayValue,
      lhs: machPortEvent.lhs,
      modifiers: modifiers
    )

    if allowAllKeys {
      return .valid(keyboardShortcut)
    }

    if let restrictedKeyCode = RestrictedKeyCode(rawValue: keyCode) {
      switch restrictedKeyCode {
      case .backspace, .delete:
        return .delete(keyboardShortcut)
      case .escape:
        return .cancel(keyboardShortcut)
      case .enter:
        return .valid(keyboardShortcut)
      }
    } else {
      return .valid(keyboardShortcut)
    }
  }

  private func run(_ workflow: Workflow, repeatingEvent: Bool) {
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
    switch workflow.execution {
    case .concurrent:
      commandRunner.concurrentRun(commands, checkCancellation: checkCancellation,
                                  resolveUserEnvironment: resolveUserEnvironment,
                                  repeatingEvent: repeatingEvent)
    case .serial:
      commandRunner.serialRun(commands, checkCancellation: checkCancellation, 
                              resolveUserEnvironment: resolveUserEnvironment,
                              repeatingEvent: repeatingEvent)
    }
  }

  private func reset(_ function: StaticString = #function, line: Int = #line) {
    previousPartialMatch = Self.defaultPartialMatch
    notifications.reset()
  }

  private func schedule(_ workflow: Workflow, after duration: Double) -> DispatchWorkItem {
    let workItem = DispatchWorkItem { [weak self] in
      guard let self else { return }

      guard self.workItem?.isCancelled != true else { return }

      self.run(workflow, repeatingEvent: false)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    return workItem
  }

  private func shouldSchedule(_ workflow: Workflow) -> Double? {
    if case .keyboardShortcuts(let trigger) = workflow.trigger,
       trigger.shortcuts.count == 1,
       let holdDuration = trigger.holdDuration,
       holdDuration > 0 {
      return holdDuration
    } else {
      return nil
    }
  }
}

enum KeyShortcutRecording: Hashable {
  case valid(KeyShortcut)
  case delete(KeyShortcut)
  case cancel(KeyShortcut)
}

private extension Collection where Element == Command {
  var isValidForRepeat: Bool {
    allSatisfy { element in
      switch element {
      case .keyboard, .menuBar, .windowManagement: true
      default:                                     false
      }
    }
  }
}

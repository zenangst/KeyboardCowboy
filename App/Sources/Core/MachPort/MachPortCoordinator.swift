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
  private var specialKeys: [Int] = [Int]()
  private var scheduledWorkItem: DispatchWorkItem?
  private var capsLockDown: Bool = false
  private var scheduledAction: ScheduleMachPortCoordinator.ScheduledAction?

  private let keyboardCleaner: KeyboardCleaner
  private let keyboardCommandRunner: KeyboardCommandRunner
  private let shortcutResolver: ShortcutResolver
  private let macroCoordinator: MacroCoordinator
  private let notifications: MachPortUINotifications
  private let scheduledMachPortCoordinator: ScheduleMachPortCoordinator
  private let recordValidator: MachPortRecordValidator
  private let store: KeyCodesStore
  private let workflowRunner: WorkflowRunner

  internal init(store: KeyCodesStore,
                keyboardCleaner: KeyboardCleaner,
                keyboardCommandRunner: KeyboardCommandRunner,
                shortcutResolver: ShortcutResolver,
                macroCoordinator: MacroCoordinator,
                mode: KeyboardCowboyMode,
                notifications: MachPortUINotifications,
                workflowRunner: WorkflowRunner) {
    self.keyboardCleaner = keyboardCleaner
    self.macroCoordinator = macroCoordinator
    self.store = store
    self.shortcutResolver = shortcutResolver
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

      if machPortEvent.type == .keyDown {
        Benchmark.shared.start("MachPortCoordinator.intercept", forceEnable: false)
      }
      intercept(machPortEvent, tryGlobals: true, runningMacro: false)
      if machPortEvent.type == .keyDown {
        Benchmark.shared.stop("MachPortCoordinator.intercept", forceEnable: false)
      }
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
  private func intercept(_ machPortEvent: MachPortEvent, tryGlobals: Bool, runningMacro: Bool) {
    if keyboardCleaner.isEnabled, keyboardCleaner.consumeEvent(machPortEvent) {
      return
    }

    if launchArguments.isEnabled(.disableMachPorts) { return }

    let machPortKeyCode = Int(machPortEvent.keyCode)
    let isRepeatingEvent: Bool = machPortEvent.event.getIntegerValueField(.keyboardEventAutorepeat) == 1
    let inMacroContext = macroCoordinator.state == .recording && !isRepeatingEvent
    let eventSignature = CGEventSignature.from(machPortEvent.event)

    switch machPortEvent.type {
    case .keyDown:
      if mode == .intercept,
         macroCoordinator.handleMacroExecution(machPortEvent, machPort: machPort, keyboardRunner: keyboardCommandRunner, workflowRunner: workflowRunner, eventSignature: eventSignature) {
        return
      }

      if case .captureKeyDown(let keyCode) = scheduledAction,
          keyCode == machPortKeyCode {
          machPortEvent.result = nil
          return
      }

      if handleEscapeKeyDownEvent(machPortEvent) { return }
    case .keyUp:
      if let workflow = previousExactMatch, workflow.machPortConditions.shouldRunOnKeyUp {
        machPortEvent.result = nil
        Task.detached { [workflowRunner] in
          await workflowRunner.run(workflow, machPortEvent: machPortEvent, repeatingEvent: false)
        }
      } else if case .captureKeyDown(let keyCode) = scheduledAction, keyCode == machPortKeyCode  {
        scheduledAction = nil
        _ = try? machPort?.post(machPortKeyCode, type: .keyDown, flags: machPortEvent.event.flags)
        _ = try? machPort?.post(machPortKeyCode, type: .keyUp, flags: machPortEvent.event.flags)
        previousPartialMatch = Self.defaultPartialMatch
        return
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

    let bundleIdentifier = UserSpace.shared.frontmostApplication.bundleIdentifier
    let userModes = UserSpace.shared.userModes.filter(\.isEnabled)
    let result = shortcutResolver.lookup(
      machPortEvent,
      bundleIdentifier: bundleIdentifier,
      userModes: userModes,
      partialMatch: previousPartialMatch
    )

    scheduledAction = nil

    switch result {
    case .none:
      let partialMatchCopy = previousPartialMatch
      handleNoMatch(result, machPortEvent: machPortEvent, isRepeatingEvent: isRepeatingEvent, runningMacro: runningMacro)
      if inMacroContext {
        macroCoordinator.record(eventSignature, kind: .event(machPortEvent), machPortEvent: machPortEvent)
      }

      let tryFallbackOnPartialMismatch = tryGlobals && partialMatchCopy.rawValue != previousPartialMatch.rawValue
      if tryFallbackOnPartialMismatch {
        intercept(machPortEvent, tryGlobals: false, runningMacro: false)
      }
    case .partialMatch(let partialMatch):
      handlePartialMatch(partialMatch, machPortEvent: machPortEvent, runningMacro: runningMacro)
    case .exact(let workflow):
      previousExactMatch = workflow
      previousPartialMatch = Self.defaultPartialMatch
      if inMacroContext {
        macroCoordinator.record(eventSignature, kind: .workflow(workflow), machPortEvent: machPortEvent)
      }
      handleExtactMatch(workflow, machPortEvent: machPortEvent, isRepeatingEvent: isRepeatingEvent)
    }
  }

  private func handlePartialMatch(_ partialMatch: PartialMatch, machPortEvent: MachPortEvent, runningMacro: Bool) {
    let onTask: @Sendable (ScheduleMachPortCoordinator.ScheduledAction?) -> Void = { [weak self] action in
      guard let self else { return }

      if macroCoordinator.state == .recording {
        macroCoordinator.record(CGEventSignature.from(machPortEvent.event),
                                kind: .event(machPortEvent),
                                machPortEvent: machPortEvent)
      }

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
              workflow.machPortConditions.isPassthrough,
              macroCoordinator.state == .recording {
      previousPartialMatch = partialMatch
      macroCoordinator.record(CGEventSignature.from(machPortEvent.event),
                              kind: .event(machPortEvent),
                              machPortEvent: machPortEvent)
    } else {
      machPortEvent.result = nil
      previousPartialMatch = partialMatch
    }

    notifications.notifyBundles(partialMatch)
  }

  @MainActor
  private func handleExtactMatch(_ workflow: Workflow, machPortEvent: MachPortEvent, isRepeatingEvent: Bool) {
    if workflow.machPortConditions.isPassthrough == true {
      // NOOP
    } else {
      machPortEvent.result = nil
    }

    let execution: @MainActor @Sendable (MachPortEvent, Bool) -> Void

    // Handle keyboard commands early to avoid cancelling previous keyboard invocations.
    if workflow.machPortConditions.enabledCommandsCount == 1,
       case .keyboard(let command) = workflow.machPortConditions.enabledCommands.first {

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

      Task.detached { await execution(machPortEvent, isRepeatingEvent) }

      repeatingResult = execution
      repeatingKeyCode = machPortEvent.keyCode
      notifications.reset()
    } else if !workflow.machPortConditions.isEmpty && workflow.machPortConditions.isValidForRepeat {
      execution = { [workflowRunner, weak self] machPortEvent, repeatingEvent in
        guard let self, machPortEvent.type != .keyUp else { return }
        self.coordinatorEvent = machPortEvent.event
        Task.detached { [workflowRunner] in
          await workflowRunner.run(workflow, machPortEvent: machPortEvent, repeatingEvent: repeatingEvent)
        }
      }

      Task.detached { await execution(machPortEvent, isRepeatingEvent) }

      repeatingResult = execution
      repeatingKeyCode = machPortEvent.keyCode
    } else if !isRepeatingEvent || workflow.machPortConditions.isValidForRepeat {
      if let delay = workflow.machPortConditions.scheduleDuration {
        scheduledWorkItem = schedule(workflow, machPortEvent: machPortEvent, after: delay)
      } else {
        Task.detached { [workflowRunner] in
          await workflowRunner.run(workflow, machPortEvent: machPortEvent, repeatingEvent: false)
        }
      }
    }
  }

  @MainActor
  private func handleNoMatch(_ result: KeyboardShortcutResult?, machPortEvent: MachPortEvent, isRepeatingEvent: Bool, runningMacro: Bool) {
    // No match, reset the lookup key
    reset()

    // Disable caps lock.
    // TODO: Add a setting for this!
    //        var newFlags = machPortEvent.event.flags
    //        newFlags.subtract(.maskAlphaShift)
    //        machPortEvent.event.flags = newFlags

    repeatingMatch = false
    coordinatorEvent = machPortEvent.event
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

      if let previousExactMatch, previousExactMatch.machPortConditions.isPassthrough == true {
        self.previousExactMatch = nil
      } else if previousPartialMatch.workflow?.machPortConditions.isPassthrough == true {
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
    } else if previousExactMatch != nil, isRepeatingEvent {
      machPortEvent.result = nil
      return true
    } else {
      repeatingResult = nil
      repeatingMatch = nil
      repeatingKeyCode = -1
      return false
    }
  }

  private func schedule(_ workflow: Workflow, machPortEvent: MachPortEvent, after duration: Double) -> DispatchWorkItem {
    let workItem = DispatchWorkItem { [weak self] in
      guard let self else { return }
      guard self.scheduledWorkItem?.isCancelled != true else { return }

      let workflowRunner = self.workflowRunner
      Task.detached {
        await workflowRunner.run(workflow, machPortEvent: machPortEvent, repeatingEvent: false)
      }
      reset()
      previousPartialMatch = Self.defaultPartialMatch
      self.scheduledWorkItem = nil
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)

    return workItem
  }
}

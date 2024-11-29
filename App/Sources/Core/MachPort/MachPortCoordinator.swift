import Carbon.HIToolbox
import Cocoa
import Combine
import Foundation
import MachPort
import InputSources
import KeyCodes
import os

@MainActor
final class MachPortCoordinator: @unchecked Sendable, ObservableObject {
  @Published private(set) var lastEventOrRebinding: CGEvent?
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
  private var repeatExecution: (@MainActor (MachPortEvent, Bool) async -> Void)?
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
    repeatExecution = nil
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

    let inMacroContext = macroCoordinator.state == .recording && !machPortEvent.isRepeat
    let eventSignature = CGEventSignature.from(machPortEvent.event, keyCode: machPortEvent.keyCode)

    switch machPortEvent.type {
    case .keyDown:
      if mode == .intercept,
         macroCoordinator.handleMacroExecution(machPortEvent, machPort: machPort, keyboardRunner: keyboardCommandRunner, workflowRunner: workflowRunner, eventSignature: eventSignature) {
        return
      }

      if case .captureKeyDown(let keyCode) = scheduledAction,
         keyCode == Int(machPortEvent.keyCode) {
        machPortEvent.result = nil
        return
      }

      if handleEscapeKeyDownEvent(machPortEvent) { return }
    case .keyUp:
      if let workflow = previousExactMatch, workflow.machPortConditions.shouldRunOnKeyUp {
        if let previousKeyDownMachPortEvent = PeekApplicationPlugin.peekEvent {
          let pressDurtion = timeElapsedInSeconds(
            start: previousKeyDownMachPortEvent.event.timestamp,
            end: machPortEvent.event.timestamp
          )
          if pressDurtion > 0.5 {
            Task.detached { [workflowRunner] in
              await workflowRunner.run(workflow, machPortEvent: machPortEvent, repeatingEvent: false)
            }
          }
          PeekApplicationPlugin.peekEvent = nil
          return
        }
      } else if case .captureKeyDown(let keyCode) = scheduledAction, keyCode == Int(machPortEvent.keyCode)  {
        scheduledAction = nil
        let machPortKeyCode = Int(machPortEvent.keyCode)
        _ = try? machPort?.post(machPortKeyCode, type: .keyDown, flags: machPortEvent.event.flags)
        _ = try? machPort?.post(machPortKeyCode, type: .keyUp, flags: machPortEvent.event.flags)
        previousPartialMatch = Self.defaultPartialMatch
        return
      }

      scheduledMachPortCoordinator.cancel()
      handleKeyUp(machPortEvent)
      scheduledWorkItem?.cancel()
      scheduledWorkItem = nil
      repeatExecution = nil
      repeatingMatch = nil
      return
    default:
      return
    }

    if handleRepeatingKeyEvent(machPortEvent) { return }

    let bundleIdentifier = UserSpace.shared.frontmostApplication.bundleIdentifier
    let userModes = UserSpace.shared.userModes.filter(\.isEnabled)
    let lookupToken: LookupToken

    // Check for use of the `Any Key`
    if let workflow = previousPartialMatch.workflow,
       workflow.machPortConditions.lastKeyIsAnyKey {
      if previousPartialMatch.rawValue.count(where: { $0 == "+" }) + 1 == workflow.machPortConditions.keyboardShortcutsTriggerCount {
        lookupToken = AnyKeyLookupToken()

        if case .exact(let workflow) = shortcutResolver.lookup(
          machPortEvent,
          bundleIdentifier: bundleIdentifier,
          userModes: userModes,
          partialMatch: .init(rawValue: ".")
        ), let rebinding = workflow.machPortConditions.rebinding,
           let keyCode = shortcutResolver.lookup(rebinding),
           let virtualKey = CGKeyCode(exactly: keyCode),
           let event = CGEvent(keyboardEventSource: nil, virtualKey: virtualKey, keyDown: true) {
          event.flags = rebinding.cgFlags
          lastEventOrRebinding = event
        } else {
          lastEventOrRebinding = machPortEvent.event
        }
      } else {
        lookupToken = machPortEvent
      }
    } else {
      lookupToken = machPortEvent
    }

    let result = shortcutResolver.lookup(
      lookupToken,
      bundleIdentifier: bundleIdentifier,
      userModes: userModes,
      partialMatch: previousPartialMatch
    )

    scheduledAction = nil

    switch result {
    case .none:
      let partialMatchCopy = previousPartialMatch
      handleNoMatch(result, machPortEvent: machPortEvent)
      if inMacroContext {
        macroCoordinator.record(eventSignature, kind: .event(machPortEvent), machPortEvent: machPortEvent)
      }

      let tryFallbackOnPartialMismatch = tryGlobals && partialMatchCopy.rawValue != previousPartialMatch.rawValue
      if tryFallbackOnPartialMismatch {
        intercept(machPortEvent, tryGlobals: false, runningMacro: false)
      }
      lastEventOrRebinding = machPortEvent.event
    case .partialMatch(let partialMatch):
      lastEventOrRebinding = machPortEvent.event
      handlePartialMatch(partialMatch, machPortEvent: machPortEvent, runningMacro: runningMacro)
    case .exact(let workflow):
      previousExactMatch = workflow
      previousPartialMatch = Self.defaultPartialMatch
      if inMacroContext {
        macroCoordinator.record(eventSignature, kind: .workflow(workflow), machPortEvent: machPortEvent)
      }
      handleExtactMatch(workflow, machPortEvent: machPortEvent)
    }
  }

  private func handlePartialMatch(_ partialMatch: PartialMatch, machPortEvent: MachPortEvent, runningMacro: Bool) {
    let onTask: @MainActor @Sendable (ScheduleMachPortCoordinator.ScheduledAction?) -> Void = { [weak self] action in
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
      if let partialWorkflow = partialMatch.workflow {
        if partialWorkflow.machPortConditions.isPassthrough == false {
          machPortEvent.result = nil
        }
      } else {
        machPortEvent.result = nil
      }
      previousPartialMatch = partialMatch
    }

    notifications.notifyBundles(partialMatch)
  }

  func timeElapsedInSeconds(start: CGEventTimestamp, end: CGEventTimestamp) -> Double {
    var timebaseInfo = mach_timebase_info_data_t()
    mach_timebase_info(&timebaseInfo)
    let elapsedTicks = end - start
    return Double(elapsedTicks) / 1_000_000_000
  }

  @MainActor
  private func handleExtactMatch(_ workflow: Workflow, machPortEvent: MachPortEvent) {
    if workflow.machPortConditions.isPassthrough != true {
      machPortEvent.result = nil
    }

    let execution: @MainActor @Sendable (MachPortEvent, Bool) async -> Void

    // Handle keyboard commands early to avoid cancelling previous keyboard invocations.
    if workflow.machPortConditions.enabledCommandsCount == 1,
       case .keyboard(let command) = workflow.machPortConditions.enabledCommands.first {

      if !machPortEvent.isRepeat {
        notifications.notifyKeyboardCommand(workflow, command: command)
      }

      execution = { [weak self, keyboardCommandRunner] machPortEvent, _ in
        guard let self else { return }
        // Don't send the original event if `allowRepeat` is `false`.
        // If we don't, then it won't send a proper key up event.
        let originalEvent = workflow.machPortConditions.allowRepeat ? machPortEvent.event : nil
        guard let newEvents = try? await keyboardCommandRunner.run(command.keyboardShortcuts,
                                                                   originalEvent: originalEvent,
                                                                   iterations: command.iterations,
                                                                   with: machPortEvent.eventSource) else {
          return
        }

        for newEvent in newEvents {
          self.coordinatorEvent = newEvent
          self.lastEventOrRebinding = newEvent
        }
      }

      Task.detached { await execution(machPortEvent, machPortEvent.isRepeat) }

      if workflow.machPortConditions.allowRepeat {
        setRepeatExecution(execution)
      } else {
        setRepeatExecution(nil)
      }
      
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

      Task.detached { await execution(machPortEvent, machPortEvent.isRepeat) }

      if workflow.machPortConditions.allowRepeat {
        setRepeatExecution(execution)
      } else {
        setRepeatExecution(nil)
      }

      repeatingKeyCode = machPortEvent.keyCode
    } else if !machPortEvent.isRepeat || workflow.machPortConditions.isValidForRepeat {
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
  private func handleNoMatch(_ result: KeyboardShortcutResult?, machPortEvent: MachPortEvent) {
    reset()
    repeatingMatch = false
    coordinatorEvent = machPortEvent.event
  }

  @MainActor
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
  @MainActor private func handleKeyUp(_ machPortEvent: MachPortEvent) {
    if let repeatExecution {
      Task.detached { await repeatExecution(machPortEvent, false) }
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
  /// - Returns: A Boolean value indicating whether the execution should return early (true) or continue (false).
  @MainActor private func handleRepeatingKeyEvent(_ machPortEvent: MachPortEvent) -> Bool {
    // If the event is repeating and there is an earlier result,
    // reuse that result to avoid unnecessary lookups.
    if machPortEvent.isRepeat, let repeatExecution, repeatingKeyCode == machPortEvent.keyCode {
      machPortEvent.result = nil
      Task.detached { await repeatExecution(machPortEvent, true) }
      return true
      // If the event is repeating and there is no earlier result,
      // simply opt-out because we don't want to lookup the same
      // keyboard shortcut over and over again.
    } else if machPortEvent.isRepeat, repeatingMatch == false {
      return true
      // Reset the repeating result and match if the event is not repeating.
    } else if previousExactMatch != nil, machPortEvent.isRepeat {
      machPortEvent.result = nil
      return true
    } else {
      repeatExecution = nil
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

  @MainActor
  private func setRepeatExecution(_ repeatExecution: (@MainActor @Sendable (MachPortEvent, Bool) async -> Void)?) {
    self.repeatExecution = repeatExecution
  }
}

private struct AnyKeyLookupToken: LookupToken {
  let keyCode: Int64
  let flags: CGEventFlags
  let signature: CGEventSignature

  init() {
    self.keyCode = Int64(KeyShortcut.anyKeyCode)
    self.flags = [.maskNonCoalesced]
    self.signature = CGEventSignature(self.keyCode, self.flags)
  }
}

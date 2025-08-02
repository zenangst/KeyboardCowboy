import Carbon.HIToolbox
import Cocoa
import Combine
import Foundation
import MachPort
import InputSources
import KeyCodes
import os

@MainActor
final class MachPortCoordinator: @unchecked Sendable, ObservableObject, TapHeldCoordinatorDelegate {
  @Published private(set) var lastEventOrRebinding: CGEvent?
  @Published private(set) var event: MachPortEvent?
  @MainActor @Published private(set) var coordinatorEvent: CGEvent?
  @Published private(set) var flagsChanged: CGEventFlags?
  @Published private(set) var recording: KeyShortcutRecording?
  @Published private(set) var mode: KeyboardCowboyMode

  @MainActor var machPort: MachPortEventController? {
    didSet {
      keyboardCommandRunner.machPort = machPort
      tapHeldCoordinator.machPort = machPort
    }
  }

  private var keyboardCowboyModeSubscription: AnyCancellable?
  private var tapHeldState: TapHeldCoordinator.State?
  private var previousPartialMatch: PartialMatch = .default()
  private var previousExactMatch: Workflow?
  private var repeatingKeyCode: Int64 = -1
  private var repeatExecution: (@MainActor (MachPortEvent, Bool) async -> Void)?
  private var repeatingMatch: Bool?
  private var specialKeys: [Int] = [Int]()
  private var scheduledWorkItem: DispatchWorkItem?
  private var capsLockDown: Bool = false
  private var clearOnFlagsChanged: Bool = false

  private let keyboardCleaner: KeyboardCleaner
  private let keyboardCommandRunner: KeyboardCommandRunner
  private let shortcutResolver: ShortcutResolver
  private let macroCoordinator: MacroCoordinator
  private let notifications: MachPortUINotifications
  private let tapHeldCoordinator: TapHeldCoordinator
  private let recordValidator: MachPortRecordValidator
  private let store: KeyCodesStore
  private let workflowRunner: WorkflowRunner

  internal init(store: KeyCodesStore,
                keyboardCleaner: KeyboardCleaner,
                keyboardCommandRunner: KeyboardCommandRunner,
                macroCoordinator: MacroCoordinator,
                mode: KeyboardCowboyMode,
                notifications: MachPortUINotifications,
                shortcutResolver: ShortcutResolver,
                tapHeldCoordinator: TapHeldCoordinator,
                workflowRunner: WorkflowRunner,
  ) {
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
    self.tapHeldCoordinator = tapHeldCoordinator
    self.tapHeldCoordinator.delegate = self
  }

  func captureUIElement() {
    mode = .captureUIElement
  }

  func startIntercept() {
    mode = .intercept
  }

  func disable() {
    mode = .disabled
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

  func receiveFlagsChanged(_ machPortEvent: MachPortEvent, allowsEscapeFallback: Bool) {
    let flags = machPortEvent.event.flags
    scheduledWorkItem?.cancel()
    scheduledWorkItem = nil
    flagsChanged = flags
    capsLockDown = machPortEvent.keyCode == kVK_CapsLock
    repeatExecution = nil
    repeatingMatch = nil
    repeatingKeyCode = -1
    KeyViewer.instance.handleFlagsChanged(machPortEvent.flags)

    if clearOnFlagsChanged && machPortEvent.flags == .maskNonCoalesced {
      previousPartialMatch = PartialMatch.default()
      clearOnFlagsChanged = false
    }

    if allowsEscapeFallback && machPortEvent.keyCode == kVK_Escape && machPortEvent.result == nil {
      _ = try? machPort?.post(kVK_Escape, type: .flagsChanged, flags: .maskNonCoalesced)
    } else if machPortEvent.keyCode == kVK_Escape && machPortEvent.flags != .maskNonCoalesced {
      Task {
        let event = machPortEvent.event
        event.type = .keyDown
        event.flags = .maskNonCoalesced
        let machPortEvent = MachPortEvent(id: machPortEvent.id, event: event, isRepeat: false)
        intercept(machPortEvent, tryGlobals: true, runningMacro: false)
      }
    }
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

      if handleRepeatingKeyEvent(machPortEvent) { return }
    case .keyUp:
      if let workflow = previousExactMatch, workflow.machPortConditions.shouldRunOnKeyUp,
         let previousKeyDownMachPortEvent = PeekApplicationPlugin.peekEvent {
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

      handleKeyUp(machPortEvent)
      scheduledWorkItem?.cancel()
      scheduledWorkItem = nil
      repeatExecution = nil
      repeatingMatch = nil
      previousExactMatch = nil
      return
    default:
      return
    }

    let bundleIdentifier = UserSpace.shared.frontmostApplication.bundleIdentifier
    let userModes = UserSpace.shared.currentUserModes.filter(\.isEnabled)
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
      tapHeldState = nil
      previousPartialMatch = PartialMatch.default()
    case .partialMatch(let partialMatch):
      lastEventOrRebinding = machPortEvent.event
      handlePartialMatch(partialMatch, machPortEvent: machPortEvent, runningMacro: runningMacro)
      KeyViewer.instance.handleInput(machPortEvent.event, store: store)
    case .exact(let workflow):
      previousExactMatch = workflow

      if case .event(let kind, _) = tapHeldState {
        switch kind {
        case .held:
          break
        case .tap:
          tapHeldState = nil
          previousPartialMatch = PartialMatch.default()
          intercept(machPortEvent, tryGlobals: true, runningMacro: false)
          return
        }
      } else if workflow.machPortConditions.keepLastPartialMatch {
        clearOnFlagsChanged = true
      } else {
        previousPartialMatch = PartialMatch.default()
        clearOnFlagsChanged = false
      }

      if inMacroContext {
        macroCoordinator.record(eventSignature, kind: .workflow(workflow), machPortEvent: machPortEvent)
      }
      handleExtactMatch(workflow, machPortEvent: machPortEvent)
    }
  }

  private func handlePartialMatch(_ partialMatch: PartialMatch, machPortEvent: MachPortEvent, runningMacro: Bool) {
    if let workflow = partialMatch.workflow,
       workflow.machPortConditions.isPassthrough,
       macroCoordinator.state == .recording {
      previousPartialMatch = partialMatch
      macroCoordinator.record(CGEventSignature.from(machPortEvent.event),
                              kind: .event(machPortEvent),
                              machPortEvent: machPortEvent)
    } else if tapHeldCoordinator.handlePartialMatchIfApplicable(partialMatch, machPortEvent: machPortEvent) {
      previousPartialMatch = partialMatch
      repeatingMatch = nil
      machPortEvent.result = nil
    } else {
      if let partialWorkflow = partialMatch.workflow,
        !partialWorkflow.machPortConditions.isPassthrough {
          machPortEvent.result = nil
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
    let execution: @MainActor @Sendable (MachPortEvent, Bool) async -> Void
    let handlePassthroughIfNeeded = {
      if !workflow.machPortConditions.isPassthrough {
        machPortEvent.result = nil
      }
    }

    // Handle keyboard commands early to avoid cancelling previous keyboard invocations.
    if workflow.machPortConditions.enabledCommandsCount == 1,
       case .keyboard(let keyboardCommand) = workflow.machPortConditions.enabledCommands.first,
       case .key(let command) = keyboardCommand.kind {

      if !machPortEvent.isRepeat {
        notifications.notifyKeyboardCommand(workflow, command: keyboardCommand)
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
          KeyViewer.instance.handleInput(newEvent, store: store)
        }
      }

      if !handleSingleKeyRebinding(workflow, machPortEvent: machPortEvent) {
        handlePassthroughIfNeeded()
        Task.detached { await execution(machPortEvent, machPortEvent.isRepeat) }
      }

      if workflow.machPortConditions.allowRepeat {
        setRepeatExecution(execution)
      } else {
        setRepeatExecution(nil)
      }
      repeatingKeyCode = machPortEvent.keyCode
      notifications.reset()
    } else if !workflow.machPortConditions.isEmpty && workflow.machPortConditions.isValidForRepeat {
      handlePassthroughIfNeeded()
      execution = { [workflowRunner, weak self] machPortEvent, repeatingEvent in
        guard let self, machPortEvent.type != .keyUp else { return }
        self.coordinatorEvent = machPortEvent.event
        KeyViewer.instance.handleInput(machPortEvent.event, store: store)
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
      handlePassthroughIfNeeded()
      KeyViewer.instance.handleInput(machPortEvent.event, store: store)
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

    if !machPortEvent.isRepeat {
      KeyViewer.instance.handleInput(machPortEvent.event, store: store)
    }
  }

  @MainActor
  private func record(_ machPortEvent: MachPortEvent) {
    machPortEvent.result = nil
    mode = .intercept
    recording = recordValidator.validate(machPortEvent, allowAllKeys: true)
  }

  private func reset(_ function: StaticString = #function, line: Int = #line) {
    previousPartialMatch = PartialMatch.default()
    notifications.reset()
  }

  /// Handles the Escape key down event.
  ///
  /// - Parameter machPortEvent: The MachPortEvent representing the key event.
  /// - Returns: A Boolean value indicating whether the execution should return early (true) or continue (false).
  private func handleEscapeKeyDownEvent(_ machPortEvent: MachPortEvent) -> Bool {
    if machPortEvent.type == .keyDown && machPortEvent.keyCode == kVK_Escape {
      notifications.reset()
      if previousPartialMatch.rawValue != PartialMatch.default().rawValue, machPortEvent.event.flags == CGEventFlags.maskNonCoalesced {
        machPortEvent.result = nil
        reset()
        tapHeldState = nil
        tapHeldCoordinator.reset()
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
      if handleSingleKeyRebinding(previousExactMatch, machPortEvent: machPortEvent) {
        self.previousExactMatch = nil
        return
      }

      Task.detached { await repeatExecution(machPortEvent, false) }
      if let previousExactMatch, previousExactMatch.machPortConditions.isPassthrough == true {
        self.previousExactMatch = nil
      } else if previousPartialMatch.workflow?.machPortConditions.isPassthrough == true {
      } else {
        self.previousExactMatch = nil
        machPortEvent.result = nil
      }
    } else if case .event(let kind, _) = tapHeldState,
              kind == .tap {
      tapHeldState = nil
      previousPartialMatch = .default()
    } else if handleSingleKeyRebinding(previousExactMatch, machPortEvent: machPortEvent) {
      self.previousExactMatch = nil
    }
  }

  private func handleSingleKeyRebinding(_ workflow: Workflow?, machPortEvent: MachPortEvent) -> Bool {
    guard let workflow,
          let keyboardShortcut = workflow.machPortConditions.rebinding,
          let keyCode = try? keyboardCommandRunner.resolveKey(for: keyboardShortcut.key) else { return false }

    let flags = keyboardCommandRunner.resolveFlags(for: keyboardShortcut, keyCode: keyCode)
    let result = machPortEvent.result?.takeUnretainedValue()
    result?.setIntegerValueField(.keyboardEventKeycode, value: Int64(keyCode))
    result?.flags = flags
    return true
  }

  /// Handles repeating key events.
  ///
  /// - Parameters:
  ///   - machPortEvent: The MachPortEvent representing the key event.
  /// - Returns: A Boolean value indicating whether the execution should return early (true) or continue (false).
  @MainActor private func handleRepeatingKeyEvent(_ machPortEvent: MachPortEvent) -> Bool {
    if handleEscapeKeyDownEvent(machPortEvent) { return true }
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
      if machPortEvent.type == .keyDown && KeyViewer.instance.isWindowOpen {
        KeyViewer.instance.handleInput(machPortEvent.event, store: store)
      } else {
        if machPortEvent.type == .keyDown {
          machPort?.ignoreNextKeyRepeat = true
        }
      }
      return true
      // Reset the repeating result and match if the event is not repeating.
    } else if previousExactMatch != nil, machPortEvent.isRepeat {
      machPortEvent.result = nil
      return true
    } else if tapHeldCoordinator.isLeader(machPortEvent) {
      machPortEvent.result = nil
      return machPortEvent.isRepeat
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
      previousPartialMatch = .default()
      self.scheduledWorkItem = nil
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)

    return workItem
  }

  @MainActor
  private func setRepeatExecution(_ repeatExecution: (@MainActor @Sendable (MachPortEvent, Bool) async -> Void)?) {
    self.repeatExecution = repeatExecution
  }

  // MARK: TapHeldCoordinatorDelegate

  func changedState(_ state: TapHeldCoordinator.State?) {
    tapHeldState = state
  }

  func didResignLeader() {
    self.previousPartialMatch = .default()
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

import Carbon.HIToolbox
import Cocoa
import Combine
import Foundation
import MachPort
import InputSources
import KeyCodes
import os

final class MachPortCoordinator {
  struct Event: Equatable {
    enum Kind {
      case flagsChanged
      case keyUp
      case keyDown
    }

    let keyboardShortcut: KeyShortcut
    let kind: Kind

    init(_ keyboardShortcut: KeyShortcut, kind: Kind) {
      self.keyboardShortcut = keyboardShortcut
      self.kind = kind
    }
  }

  enum RestrictedKeyCode: Int, CaseIterable {
    case backspace = 117
    case delete = 51
    case enter = 36
    case escape = 53
  }

  @Published var recording: KeyShortcutRecording?

  var machPort: MachPortEventController? {
    didSet { keyboardCommandRunner.machPort = machPort }
  }

  private static let defaultPartialMatch: PartialMatch = .init(rawValue: ".")
  private var previousPartialMatch: PartialMatch = .init(rawValue: ".")

  private var keyboardCowboyModeSubscription: AnyCancellable?
  private var machPortEventSubscription: AnyCancellable?
  private var flagsChangedSubscription: AnyCancellable?
  private var mode: KeyboardCowboyMode
  private var specialKeys: [Int] = [Int]()

  private var shouldHandleKeyUp: Bool = false

  private var workItem: DispatchWorkItem?

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

  func subscribe(to publisher: Published<KeyboardCowboyMode?>.Publisher) {
    keyboardCowboyModeSubscription = publisher
      .compactMap({ $0 })
      .sink { [weak self] mode in
        guard let self else { return }
        self.mode = mode
        self.specialKeys = Array(self.store.specialKeys().keys)
      }
  }

  func subscribe(to publisher: Published<MachPortEvent?>.Publisher) {
    machPortEventSubscription = publisher
      .compactMap { $0 }
      .sink { [weak self] event in
        guard let self = self else { return }
        switch self.mode {
        case .intercept:
          self.intercept(event)
        case .record:
          self.record(event)
        case .disabled:
          break
        }
      }
  }

  func subscribe(to publisher: Published<CGEventFlags?>.Publisher) {
    flagsChangedSubscription = publisher
      .compactMap { $0 }
      .sink { [weak self] recording in
        self?.workItem?.cancel()
        self?.workItem = nil
      }
  }

  private func intercept(_ machPortEvent: MachPortEvent, tryGlobals: Bool = false) {
    if launchArguments.isEnabled(.disableMachPorts) { return }

    let isRepeatingEvent: Bool = machPortEvent.event.getIntegerValueField(.keyboardEventAutorepeat) == 1
    let kind: Event.Kind
    switch machPortEvent.type {
    case .flagsChanged:
      kind = .flagsChanged
    case .keyDown:
      kind = .keyDown

      if previousPartialMatch.rawValue != Self.defaultPartialMatch.rawValue,
         machPortEvent.keyCode == kVK_Escape {
        if machPortEvent.event.flags == CGEventFlags.maskNonCoalesced {
          machPortEvent.result = nil
          reset()
          return
        }
      }

    case .keyUp:
      kind = .keyUp
      workItem?.cancel()
      workItem = nil
    default:
      return
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
      let keyboardShortcut = KeyShortcut(key: displayValue.uppercased(), lhs: machPortEvent.lhs, modifiers: modifiers)
      result = keyboardShortcutsController.lookup(
        keyboardShortcut,
        bundleIdentifier: UserSpace.shared.frontMostApplication.bundleIdentifier,
        userModes: userModes,
        partialMatch: previousPartialMatch
      )
    }

    switch result {
    case .partialMatch(let partialMatch):
      if let workflow = partialMatch.workflow,
         workflow.trigger?.isPassthrough == true {
        // NOOP
      } else {
        machPortEvent.result = nil
      }

      if kind == .keyDown {
        notifications.notifyBundles(partialMatch)
        previousPartialMatch = partialMatch
      }
    case .exact(let workflow):
      if workflow.trigger?.isPassthrough == true {
        // NOOP
      } else {
        machPortEvent.result = nil
      }

      if workflow.commands.filter(\.isEnabled).count == 1,
         case .keyboard(let command) = workflow.commands.first(where: \.isEnabled) {
        if !isRepeatingEvent && machPortEvent.event.type == .keyDown {
          notifications.notifyKeyboardCommand(workflow, command: command)
        }

        try? keyboardCommandRunner.run(command.keyboardShortcuts,
                                       type: machPortEvent.type,
                                       originalEvent: machPortEvent.event,
                                       with: machPortEvent.eventSource)
        previousPartialMatch = Self.defaultPartialMatch
      } else if workflow.commands.allSatisfy({
        if case .windowManagement = $0 { return true } else { return false }
      }) {
        guard machPortEvent.type == .keyDown else { return }
        run(workflow)
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
          run(workflow)
        }
      } else if kind == .keyDown, !isRepeatingEvent {
        if let delay = shouldSchedule(workflow) {
          workItem = schedule(workflow, after: delay)
        } else {
          run(workflow)
        }

        previousPartialMatch = Self.defaultPartialMatch
      }
    case .none:
      if kind == .keyDown {
        // No match, reset the lookup key
        reset()

        if !tryGlobals {
          intercept(machPortEvent, tryGlobals: true)
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

  private func run(_ workflow: Workflow) {
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
                                  resolveUserEnvironment: resolveUserEnvironment
      )
    case .serial:
      commandRunner.serialRun(commands, checkCancellation: checkCancellation, 
                              resolveUserEnvironment: resolveUserEnvironment)
    }
  }

  private func reset() {
    previousPartialMatch = Self.defaultPartialMatch
    notifications.reset()
  }

  private func schedule(_ workflow: Workflow, after duration: Double) -> DispatchWorkItem {
    let workItem = DispatchWorkItem { [weak self] in
      guard let self else { return }

      guard self.workItem?.isCancelled != true else { return }

      self.run(workflow)
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

public enum KeyShortcutRecording: Hashable {
  case valid(KeyShortcut)
  case delete(KeyShortcut)
  case cancel(KeyShortcut)
}

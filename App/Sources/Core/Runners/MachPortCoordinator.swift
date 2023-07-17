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
  private var mode: KeyboardCowboyMode
  private var specialKeys: [Int] = [Int]()

  private var shouldHandleKeyUp: Bool = false

  private let commandRunner: CommandRunner
  private let keyboardCommandRunner: KeyboardCommandRunner
  private let keyboardShortcutsController: KeyboardShortcutsController
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

  private func intercept(_ machPortEvent: MachPortEvent) {
    if launchArguments.isEnabled(.disableMachPorts) { return }

    let isRepeatingEvent: Bool = machPortEvent.event.getIntegerValueField(.keyboardEventAutorepeat) == 1
    let kind: Event.Kind
    switch machPortEvent.type {
    case .flagsChanged:
      kind = .flagsChanged
    case .keyDown:
      kind = .keyDown
    case .keyUp:
      kind = .keyUp
    default:
      return
    }

    guard let displayValue = store.displayValue(for: Int(machPortEvent.keyCode)) else {
      return
    }
    let modifiers = VirtualModifierKey.fromCGEvent(machPortEvent.event, specialKeys: specialKeys)
      .compactMap({ ModifierKey(rawValue: $0.rawValue) })
    let keyboardShortcut = KeyShortcut(key: displayValue, lhs: machPortEvent.lhs, modifiers: modifiers)

    // Found a match
    var result = keyboardShortcutsController.lookup(keyboardShortcut, partialMatch: previousPartialMatch)
    if result == nil {
      let keyboardShortcut = KeyShortcut(key: displayValue.uppercased(), lhs: machPortEvent.lhs, modifiers: modifiers)
      result = keyboardShortcutsController.lookup(keyboardShortcut, partialMatch: previousPartialMatch)
    }

    switch result {
    case .partialMatch(let match):
      if let workflow = match.workflow,
         workflow.trigger?.isPassthrough == true {
        // NOOP
      } else {
        machPortEvent.result = nil
      }
      if kind == .keyDown {
        previousPartialMatch = match
      }
    case .exact(let workflow):
      if workflow.trigger?.isPassthrough == true {
        // NOOP
      } else {
        machPortEvent.result = nil
      }

      if workflow.commands.count == 1,
         case .keyboard(let command) = workflow.commands.first(where: \.isEnabled) {
        try? keyboardCommandRunner.run(command,
                                       type: machPortEvent.type,
                                       originalEvent: machPortEvent.event,
                                       with: machPortEvent.eventSource)
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

        switch workflow.execution {
        case .concurrent:
          commandRunner.concurrentRun(workflow.commands)
        case .serial:
          commandRunner.serialRun(workflow.commands)
        }
      } else if kind == .keyDown, !isRepeatingEvent {
        let commands = workflow.commands.filter(\.isEnabled)

        switch workflow.execution {
        case .concurrent:
          commandRunner.concurrentRun(commands)
        case .serial:
          commandRunner.serialRun(commands)
        }

        previousPartialMatch = Self.defaultPartialMatch
      }
    case .none:
      if kind == .keyDown {
        // No match, reset the lookup key
        previousPartialMatch = Self.defaultPartialMatch
      }
    }
  }

  private func record(_ machPortEvent: MachPortEvent) {
    machPortEvent.result = nil

    let recording = validate(machPortEvent)

    switch recording {
    case .valid:
      mode = .intercept
    case .delete, .cancel:
      break
    }

    self.recording = recording
  }

  private func validate(_ machPortEvent: MachPortEvent) -> KeyShortcutRecording {
    let validationContext: KeyShortcutRecording
    let keyCode = Int(machPortEvent.keyCode)

    guard let displayValue = store.displayValue(for: keyCode) else {
      validationContext = .cancel(.empty())
      return validationContext
    }

    let virtualModifiers = VirtualModifierKey
      .fromCGEvent(machPortEvent.event,
                   specialKeys: Array(store.specialKeys().keys))
    let modifiers = virtualModifiers
      .compactMap({ ModifierKey(rawValue: $0.rawValue) })
    let keyboardShortcut = KeyShortcut(key: displayValue, lhs: machPortEvent.lhs, modifiers: modifiers)
    if let restrictedKeyCode = RestrictedKeyCode(rawValue: Int(machPortEvent.keyCode)) {
      switch restrictedKeyCode {
      case .backspace, .delete:
        validationContext = .delete(keyboardShortcut)
      case .escape:
        validationContext = .cancel(keyboardShortcut)
      case .enter:
        validationContext = .valid(keyboardShortcut)
      }
    } else {
      validationContext = .valid(keyboardShortcut)
    }

    return validationContext
  }
}

public enum KeyShortcutRecording: Hashable {
  case valid(KeyShortcut)
  case delete(KeyShortcut)
  case cancel(KeyShortcut)
}

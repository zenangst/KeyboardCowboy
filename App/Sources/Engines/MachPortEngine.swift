import Carbon.HIToolbox
import Cocoa
import Combine
import Foundation
import MachPort
import InputSources
import KeyCodes
import os

final class MachPortEngine {
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
    didSet { keyboardEngine.machPort = machPort }
  }

  private static let previousKeyDefault = "."

  private var previousKey: String = "."
  private var keyboardCowboyModeSubscription: AnyCancellable?
  private var machPortEventSubscription: AnyCancellable?
  private var mode: KeyboardCowboyMode
  private var specialKeys: [Int] = [Int]()

  private var shouldHandleKeyUp: Bool = false

  private let commandEngine: CommandEngine
  private let keyboardEngine: KeyboardEngine
  private let keyboardShortcutsCache: KeyboardShortcutsCache
  private let store: KeyCodesStore

  internal init(store: KeyCodesStore,
                commandEngine: CommandEngine,
                keyboardEngine: KeyboardEngine,
                keyboardShortcutsCache: KeyboardShortcutsCache,
                mode: KeyboardCowboyMode) {
    self.commandEngine = commandEngine
    self.store = store
    self.keyboardShortcutsCache = keyboardShortcutsCache
    self.keyboardEngine = keyboardEngine
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
    let result = keyboardShortcutsCache.lookup(keyboardShortcut, previousKey: previousKey)

    switch result {
    case .partialMatch(let key):
      machPortEvent.result = nil
      if kind == .keyDown {
        previousKey = key
      }
    case .exact(let workflow):
      machPortEvent.result = nil

      if workflow.commands.count == 1,
         case .keyboard(let command) = workflow.commands.first(where: \.isEnabled) {
        try? keyboardEngine.run(command,
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
          commandEngine.concurrentRun(workflow.commands)
        case .serial:
          commandEngine.serialRun(workflow.commands)
        }
      } else if workflow.commands.allSatisfy({
        if case .keyboard = $0 { return true } else { return false }
      }) {
        let keyboardCommands = workflow.commands
          .filter(\.isEnabled)
          .compactMap {
            if case .keyboard(let command) = $0 {
              return command
            } else {
              return nil
            }
          }
        Task {
          for command in keyboardCommands {
            try? keyboardEngine.run(command,
                                    type: .keyDown,
                                    originalEvent: machPortEvent.event,
                                    with: machPortEvent.eventSource)
            try await Task.sleep(for: .milliseconds(75))
            try? keyboardEngine.run(command,
                                    type: .keyUp,
                                    originalEvent: machPortEvent.event,
                                    with: machPortEvent.eventSource)
          }
        }
      } else if kind == .keyDown, !isRepeatingEvent {
        let commands = workflow.commands.filter(\.isEnabled)

        switch workflow.execution {
        case .concurrent:
          commandEngine.concurrentRun(commands)
        case .serial:
          commandEngine.serialRun(commands)
        }

        previousKey = Self.previousKeyDefault
      }
    case .none:
      if kind == .keyDown {
        // No match, reset the lookup key
        previousKey = Self.previousKeyDefault
      }
    }
  }

  private func record(_ machPortEvent: MachPortEvent) {
    machPortEvent.result = nil

    let recording = validate(machPortEvent)

    switch recording {
    case .valid:
      mode = .intercept
    case .systemShortcut:
      break
    case .delete:
      break
    case .cancel:
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
    let systemShortcuts = store.systemKeys()
      .first(where: { $0.keyCode == keyCode && $0.modifiers ==  virtualModifiers })

    //    if systemShortcuts != nil {
    //      validationContext = .systemShortcut(keyboardShortcut)
    //    } else
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
  case systemShortcut(KeyShortcut)
  case delete(KeyShortcut)
  case cancel(KeyShortcut)
}

private extension MachPortEvent {
  func isSame(as otherEvent: MachPortEvent) -> Bool {
    keyCode == otherEvent.keyCode &&
    type == otherEvent.type
  }
}

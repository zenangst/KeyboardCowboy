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
  private var lastEvent: MachPortEvent?
  private var subscriptions = Set<AnyCancellable>()
  private var mode: KeyboardCowboyMode
  private var specialKeys: [Int] = [Int]()

  private let commandEngine: CommandEngine
  private let keyboardEngine: KeyboardEngine
  private let keyboardShortcutsCache: KeyboardShortcutsCache
  private let store: KeyCodesStore

  internal init(store: KeyCodesStore,
                commandEngine: CommandEngine,
                keyboardShortcutsCache: KeyboardShortcutsCache,
                mode: KeyboardCowboyMode) {
    self.commandEngine = commandEngine
    self.store = store
    self.keyboardShortcutsCache = keyboardShortcutsCache
    self.keyboardEngine = .init(store: store)
    self.mode = mode
    self.specialKeys = Array(store.specialKeys().keys)
  }

  func subscribe(to publisher: Published<KeyboardCowboyMode?>.Publisher) {
    publisher
      .compactMap({ $0 })
      .sink { [weak self] mode in
        guard let self else { return }
        self.mode = mode
        self.specialKeys = Array(self.store.specialKeys().keys)
      }.store(in: &subscriptions)
  }

  func subscribe(to publisher: Published<MachPortEvent?>.Publisher) {
    publisher
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
      }.store(in: &subscriptions)
  }

  private func intercept(_ machPortEvent: MachPortEvent) {
    guard KeyboardCowboy.env == .production else { return }

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
      } else {
        lastEvent = nil
      }
    case .exact(let workflow):
      machPortEvent.result = nil
      switch workflow.commands.last {
      case .keyboard(let command):
        try? keyboardEngine.run(command,
                                type: machPortEvent.type,
                                originalEvent: machPortEvent.event,
                                with: machPortEvent.eventSource)
      default:
        if kind == .keyDown {
          // Avoid running commands on key down.
          if let lastEvent, lastEvent.isSame(as: machPortEvent) { return }

          commandEngine.serialRun(workflow.commands.filter(\.isEnabled))
          previousKey = Self.previousKeyDefault
          lastEvent = machPortEvent
        } else {
          lastEvent = nil
        }
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
      case .escape, .enter:
        validationContext = .cancel(keyboardShortcut)
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

import Carbon.HIToolbox
import Cocoa
import Combine
import Foundation
import os

final class MachPortEngine {
  enum RestrictedKeyCode: Int, CaseIterable {
    case backspace = 117
    case delete = 51
    case enter = 36
    case escape = 53
  }

  @Published var keystroke: KeyShortcut?
  @Published var recording: KeyShortcutRecording?

  private var activeKeyboardShortcuts = [KeyShortcut]()
  private var activeWorkflows = [Workflow]()
  private var subscriptions = Set<AnyCancellable>()
  private var mode: KeyboardCowboyMode

  private let keyboardEngine: KeyboardEngine
  private let store: KeyCodeStore

  internal init(store: KeyCodeStore) {
    self.store = store
    self.keyboardEngine = .init(store: store)
    self.mode = .intercept
  }

  func subscribe(to publisher: Published<KeyboardCowboyMode?>.Publisher) {
    publisher
      .compactMap({ $0 })
      .sink { [weak self] mode in
        self?.mode = mode
      }.store(in: &subscriptions)
  }

  func subscribe(to publisher: Published<[Workflow]>.Publisher) {
    publisher.sink { [weak self] workflows in
      self?.activeWorkflows = workflows
    }.store(in: &subscriptions)
  }

  func subscribe(to publisher: Published<[KeyShortcut]>.Publisher) {
    publisher.sink { [weak self] keyboardShortcuts in
      self?.activeKeyboardShortcuts = keyboardShortcuts
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
    let counter = activeKeyboardShortcuts.count

    for workflow in activeWorkflows {
      guard case let .keyboardShortcuts(shortcuts) = workflow.trigger,
            !shortcuts.isEmpty,
            counter < shortcuts.count
            else { continue }

      let keyboardShortcut = shortcuts[counter]

      guard let keyCode = store.keyCode(for: keyboardShortcut.key.uppercased()),
            machPortEvent.keyCode == keyCode else {
        continue
      }

      let eventModifiers = ModifierKey.fromCGEvent(
        machPortEvent.event,
        specialKeys: Array(KeyCodes.specialKeys.keys))

      var modifiersMatch: Bool = true
      if let modifiers = keyboardShortcut.modifiers {
        modifiersMatch = eventModifiers == modifiers
      } else {
        modifiersMatch = eventModifiers.isEmpty
      }

      guard modifiersMatch else { continue }

      // Intercept the mach port event by removing the result.
      // The result in this case is the original `CGEvent` which we want
      // to discard in order to only run the configured actions based on
      // the workflows.
      machPortEvent.result = nil

      if keyboardShortcut == shortcuts.last {
        switch workflow.commands.last {
        case .keyboard(let command):
          try? keyboardEngine.run(command, type: machPortEvent.type,
                                  with: machPortEvent.eventSource)
        default:
          if machPortEvent.type == .keyDown {
            self.keystroke = keyboardShortcut
          }
        }
      } else {
        self.keystroke = keyboardShortcut
      }

      break
    }
  }

  private func record(_ event: MachPortEvent) {
    event.result = nil

    let recording = validate(event)

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

  private func validate(_ event: MachPortEvent) -> KeyShortcutRecording {
    let inputSource = InputSourceController().currentInputSource()
    let keyCode = Int(event.keyCode)
    guard let container = try? store.mapInputSource(inputSource, keyCode: keyCode, modifiers: 0) else {
      return .systemShortcut(.empty())
    }

    let validationContext: KeyShortcutRecording
    var keyboardShortcut: KeyShortcut
    let modifiers = ModifierKey.fromCGEvent(event.event, specialKeys: Array(KeyCodes.specialKeys.keys))

    keyboardShortcut = KeyShortcut(
      id: UUID().uuidString,
      key: container.displayValue,
      modifiers: modifiers)

    let systemKeyboardShortcut = getSystemShortcuts()
      .first(where: { $0.key == keyboardShortcut.key &&
              $0.modifiers == keyboardShortcut.modifiers })
    if let systemKeyboardShortcut = systemKeyboardShortcut {
      validationContext = .systemShortcut(systemKeyboardShortcut)
    } else if let restrictedKeyCode = RestrictedKeyCode(rawValue: Int(event.keyCode)) {
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

  private func getSystemShortcuts() -> [KeyShortcut] {
    let inputSource = InputSourceController().currentInputSource()
    var result = [KeyShortcut]()
    var shortcutsUnmanaged: Unmanaged<CFArray>?
    guard
      CopySymbolicHotKeys(&shortcutsUnmanaged) == noErr,
      let shortcuts = shortcutsUnmanaged?.takeRetainedValue() as? [[String: Any]]
    else {
      assertionFailure("Could not get system keyboard shortcuts")
      return []
    }

    for shortcut in shortcuts {
      guard
        (shortcut[kHISymbolicHotKeyEnabled] as? Bool) == true,
        let carbonKeyCode = shortcut[kHISymbolicHotKeyCode] as? Int,
        let carbonModifiers = shortcut[kHISymbolicHotKeyModifiers] as? Int,
        let container = try? store.mapInputSource(inputSource, keyCode: carbonKeyCode, modifiers: UInt32(carbonModifiers))
      else {
        continue
      }

      let nsEventFlags = NSEvent.ModifierFlags(carbon: carbonModifiers)
      let modifiers = ModifierKey.fromNSEvent(nsEventFlags)
      let keyboardShortcut = KeyShortcut(key: container.displayValue, modifiers: modifiers)
      result.append(keyboardShortcut)
    }

    return result
  }
}

public enum KeyShortcutRecording {
  case valid(KeyShortcut)
  case systemShortcut(KeyShortcut)
  case delete(KeyShortcut)
  case cancel(KeyShortcut)
}

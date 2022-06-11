import Carbon.HIToolbox
import Cocoa
import Combine
import Foundation
import MachPort
import InputSources
import KeyCodes
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

  private var topLevelIndex = Set<String>()
  private var activeKeyboardShortcuts = [KeyShortcut]()
  private var activeWorkflows = [Workflow]()
  private var subscriptions = Set<AnyCancellable>()
  private var mode: KeyboardCowboyMode

  private let keyboardEngine: KeyboardEngine
  private let store: KeyCodesStore

  internal init(store: KeyCodesStore, mode: KeyboardCowboyMode) {
    self.store = store
    self.keyboardEngine = .init(store: store)
    self.mode = mode
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
      let topLevelArray = workflows.compactMap { workflow in
        if case .keyboardShortcuts(let shortcuts) = workflow.trigger,
           let first = shortcuts.first {
          return first.validationValue
        }
        return nil
      }
      self?.topLevelIndex = Set(topLevelArray)
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

    // Verify that the top-level shortcut matches before going forward with any processing of keyboard shortcuts.
    // If there aren't any matches at the top-level, there is no point in going forward from here on out
    // and the `intercept` method will throw an early return.
    if counter == 0 {
      guard let displayValue = store.displayValue(for: Int(machPortEvent.keyCode)),
            let rawValue = store.string(for: Int(machPortEvent.keyCode)) else { return }
      let modifiers = VirtualModifierKey.fromCGEvent(machPortEvent.event,
                                                     specialKeys: Array(store.specialKeys().keys))
        .compactMap({ ModifierKey(rawValue: $0.rawValue) })
      let keyShortcutDisplayValue = KeyShortcut(key: displayValue, modifiers: modifiers)
      let keyShortcutRawValue = KeyShortcut(key: rawValue, modifiers: modifiers)

      if topLevelIndex.contains(keyShortcutDisplayValue.validationValue) {
      } else if topLevelIndex.contains(keyShortcutRawValue.validationValue) {
      } else {
        return
      }
    }

    for workflow in activeWorkflows {
      guard case let .keyboardShortcuts(shortcuts) = workflow.trigger,
            !shortcuts.isEmpty,
            counter < shortcuts.count
            else { continue }

      let keyboardShortcut = shortcuts[counter]

      guard let keyCode = store.keyCode(for: keyboardShortcut.key, matchDisplayValue: true),
            machPortEvent.keyCode == keyCode else {
        continue
      }

      let virtualModifiers = VirtualModifierKey.fromCGEvent(machPortEvent.event,
                                                            specialKeys: Array(store.specialKeys().keys))

      var modifiersMatch: Bool = true
      if let modifiers = keyboardShortcut.modifiers {
        let shadowedModifiers = virtualModifiers.compactMap({ ModifierKey.init(rawValue: $0.rawValue) })
        modifiersMatch = shadowedModifiers == modifiers
      } else {
        modifiersMatch = virtualModifiers.isEmpty
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
    let keyboardShortcut = KeyShortcut(key: displayValue, modifiers: modifiers)
    let systemShortcuts = store.systemKeys()
      .first(where: { $0.keyCode == keyCode && $0.modifiers ==  virtualModifiers })

    if systemShortcuts != nil {
      validationContext = .systemShortcut(keyboardShortcut)
    } else if let restrictedKeyCode = RestrictedKeyCode(rawValue: Int(machPortEvent.keyCode)) {
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

public enum KeyShortcutRecording {
  case valid(KeyShortcut)
  case systemShortcut(KeyShortcut)
  case delete(KeyShortcut)
  case cancel(KeyShortcut)
}

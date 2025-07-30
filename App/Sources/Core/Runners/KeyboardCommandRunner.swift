import Foundation
import MachPort
import CoreGraphics
import KeyCodes

enum KeyboardCommandRunnerError: Error {
  case failedToResolveMachPortController
  case failedToResolveKey(String)
  case failedToCreateKeyCode(Int)
  case failedToCreateEvent
}

@MainActor
final class KeyboardCommandRunner: @unchecked Sendable {
  var machPort: MachPortEventController?
  let store: KeyCodesStore

  internal init(store: KeyCodesStore) {
    self.store = store
  }

  @MainActor
  func virtualKey(for string: String, modifiers: [VirtualModifierKey] = [], matchDisplayValue: Bool = true) -> VirtualKey? {
    store.virtualKey(for: string, modifiers: modifiers, matchDisplayValue: matchDisplayValue)
  }

  @discardableResult
  @MainActor
  func run(_ keyboardShortcuts: [KeyShortcut],
           originalEvent: CGEvent? = nil,
           iterations: Int,
           isRepeating: Bool = false,
           with eventSource: CGEventSource?) async throws -> [CGEvent] {
    guard let machPort else {
      throw KeyboardCommandRunnerError.failedToResolveMachPortController
    }

    let isRepeat = originalEvent?.getIntegerValueField(.keyboardEventAutorepeat) == 1
    let iterations = max(1, iterations)
    var events = [CGEvent]()
    let count = keyboardShortcuts.count

    for _ in 1...iterations {
      for keyboardShortcut in keyboardShortcuts {
        do {
          let key = try resolveKey(for: keyboardShortcut.key)
          let flags = resolveFlags(for: keyboardShortcut, keyCode: key)
          let configureEvent: (CGEvent) -> Void = { newEvent in
            if let originalEvent {
              let originalKeyboardEventAutorepeat = originalEvent.getIntegerValueField(.keyboardEventAutorepeat)
              newEvent.setIntegerValueField(.keyboardEventAutorepeat, value: count > 1 ? 0 : originalKeyboardEventAutorepeat)
            } else if isRepeating {
              newEvent.setIntegerValueField(.keyboardEventAutorepeat, value: count > 1 ? 0 : 1)
            }
          }

          let shouldPostKeyDown = originalEvent == nil || originalEvent?.type == .keyDown
          let shouldPostKeyUp = originalEvent == nil   || (!isRepeat && originalEvent?.type == .keyUp)

          if shouldPostKeyDown {
            let keyDown = try machPort.post(key, type: .keyDown, flags: flags, configure: configureEvent)
            events.append(keyDown)
          }

          if shouldPostKeyUp {
            let keyUp = try machPort.post(key, type: .keyUp, flags: flags, configure: configureEvent)
            events.append(keyUp)
          }
        } catch let error {
          throw error
        }
      }
    }

    return events
  }

  func resolveKey(for string: String) throws -> Int {
    let uppercased = string.uppercased()

    if let uppercasedResult = store.keyCode(for: uppercased, matchDisplayValue: true) {
      return uppercasedResult
    }
    if let stringResult = store.keyCode(for: string, matchDisplayValue: true) {
      return stringResult
    }

    throw KeyboardCommandRunnerError.failedToResolveKey(string)
  }

  func resolveFlags(for keyboardShortcut: KeyShortcut, keyCode: Int) -> CGEventFlags {
    var flags = keyboardShortcut.cgFlags
    if keyboardShortcut.key.hasPrefix("F") {
      flags.insert(.maskSecondaryFn)
      // NX_DEVICELCMDKEYMASK
      flags.insert(CGEventFlags(rawValue: 8))
    }

    let arrowKeys: ClosedRange<Int> = 123...126
    if arrowKeys.contains(keyCode) {
      flags.insert(.maskNumericPad)
    }
    return flags
  }
}

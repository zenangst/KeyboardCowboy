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

final class KeyboardCommandRunner: @unchecked Sendable {
  var machPort: MachPortEventController?
  let store: KeyCodesStore

  internal init(store: KeyCodesStore) {
    self.store = store
  }

  func virtualKey(for string: String, modifiers: [VirtualModifierKey] = [], matchDisplayValue: Bool = true) -> VirtualKey? {
    store.virtualKey(for: string, modifiers: modifiers, matchDisplayValue: matchDisplayValue)
  }

  @discardableResult
  func run(_ keyboardShortcuts: [KeyShortcut],
           originalEvent: CGEvent? = nil,
           isRepeating: Bool = false,
           with eventSource: CGEventSource?) throws -> [CGEvent] {
    guard let machPort else {
      throw KeyboardCommandRunnerError.failedToResolveMachPortController
    }

    let isRepeat = originalEvent?.getIntegerValueField(.keyboardEventAutorepeat) == 1

    var events = [CGEvent]()
    for keyboardShortcut in keyboardShortcuts {
      let key = try resolveKey(for: keyboardShortcut.key)
      var flags = CGEventFlags()
      keyboardShortcut.modifiers.forEach { flags.insert($0.cgModifierFlags) }
      do {
        var flags = flags
        // In applications like Xcode, we need to set the numeric pad flag for
        // the application to properly respond to arrow key events as if the
        // user used the actual arrow keys to navigate.
        let arrows = 123...126
        flags.insert(.maskNonCoalesced)
        if arrows.contains(key) {
          flags.insert(.maskNumericPad)
        }

        let configureEvent: (CGEvent) -> Void = { newEvent in
          if let originalEvent {
            let originalKeyboardEventAutorepeat = originalEvent.getIntegerValueField(.keyboardEventAutorepeat)
            newEvent.setIntegerValueField(.keyboardEventAutorepeat, value: originalKeyboardEventAutorepeat)
          } else if isRepeating {
            newEvent.setIntegerValueField(.keyboardEventAutorepeat, value: 1)
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
    return events
  }

  // MARK: Private methods

  private func resolveKey(for string: String) throws -> Int {
    let uppercased = string.uppercased()

    if let uppercasedResult = store.keyCode(for: uppercased, matchDisplayValue: true) {
      return uppercasedResult
    }
    if let stringResult = store.keyCode(for: string, matchDisplayValue: true) {
      return stringResult
    }

    throw KeyboardCommandRunnerError.failedToResolveKey(string)
  }
}

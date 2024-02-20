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
           type: CGEventType,
           originalEvent: CGEvent?,
           with eventSource: CGEventSource?) throws -> [CGEvent] {
    guard let machPort else {
      throw KeyboardCommandRunnerError.failedToResolveMachPortController
    }

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
        if arrows.contains(key) {
          flags.insert(.maskNumericPad)
        }

        let newEvent = try machPort.post(key, type: type, flags: flags) { newEvent in
          if let originalEvent {
            let originalKeyboardEventAutorepeat = originalEvent.getIntegerValueField(.keyboardEventAutorepeat)
            newEvent.setIntegerValueField(.keyboardEventAutorepeat, value: originalKeyboardEventAutorepeat)
          }
        }
        events.append(newEvent)
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

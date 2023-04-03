import Foundation
import MachPort
import CoreGraphics
import KeyCodes

final class KeyboardEngine {
  enum KeyboardEngineError: Error {
    case failedToResolveMachPortController
    case failedToResolveKey(String)
    case failedToCreateKeyCode(Int)
    case failedToCreateEvent
  }

  var machPort: MachPortEventController?
  let store: KeyCodesStore

  internal init(store: KeyCodesStore) {
    self.store = store
  }

  func virtualKey(for string: String) -> VirtualKey? {
    store.virtualKey(for: string)
  }

  func run(_ command: KeyboardCommand,
           type: CGEventType,
           originalEvent: CGEvent?,
           with eventSource: CGEventSource?) throws {
    guard let machPort else {
      throw KeyboardEngineError.failedToResolveMachPortController
    }

    for keyboardShortcut in command.keyboardShortcuts {
      let key = try resolveKey(for: keyboardShortcut.key)
      var flags = CGEventFlags()
      keyboardShortcut.modifiers.forEach { flags.insert($0.cgModifierFlags) }
      do {
        try machPort.post(key, type: type, flags: flags) { newEvent in
          if let originalEvent {
            let originalKeyboardEventAutorepeat = originalEvent.getIntegerValueField(.keyboardEventAutorepeat)
            newEvent.setIntegerValueField(.keyboardEventAutorepeat, value: originalKeyboardEventAutorepeat)
          }
        }
      } catch let error {
        FileLogger.log("⌨️ Failed: \(keyboardShortcut)")
        throw error
      }
    }
  }

  private func resolveKey(for string: String) throws -> Int {
    let uppercased = string.uppercased()

    if let uppercasedResult = store.keyCode(for: uppercased, matchDisplayValue: true) {
      return uppercasedResult
    }
    if let stringResult = store.keyCode(for: string, matchDisplayValue: true) {
      return stringResult
    }

    throw KeyboardEngineError.failedToResolveKey(string)
  }
}

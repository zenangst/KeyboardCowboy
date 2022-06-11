import Foundation
import CoreGraphics

final class KeyboardEngine {
  enum KeyboardEngineError: Error {
    case failedToResolveKey(String)
    case failedToCreateKeyCode(Int)
    case failedToCreateEvent
  }

  private let store: KeyCodesStore

  internal init(store: KeyCodesStore) {
    self.store = store
  }

  func run(_ command: KeyboardCommand, type: CGEventType, with eventSource: CGEventSource?) throws {
    let string = command.keyboardShortcut.key.uppercased()

    guard let key = store.keyCode(for: string, matchDisplayValue: true) else {
      throw KeyboardEngineError.failedToResolveKey(string)
    }

    var flags = CGEventFlags()
    command.keyboardShortcut.modifiers?.forEach { flags.insert($0.cgModifierFlags) }

    guard let cgKeyCode = CGKeyCode(exactly: key) else {
      throw KeyboardEngineError.failedToCreateKeyCode(key)
    }

    guard let cgEvent = CGEvent(keyboardEventSource: eventSource,
                                virtualKey: cgKeyCode,
                                keyDown: type == .keyDown) else {
      throw KeyboardEngineError.failedToCreateEvent
    }

    cgEvent.flags = flags
    cgEvent.post(tap: .cghidEventTap)
  }
}

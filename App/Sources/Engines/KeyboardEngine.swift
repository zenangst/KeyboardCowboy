import Foundation
import MachPort
import CoreGraphics

final class KeyboardEngine {
  enum KeyboardEngineError: Error {
    case failedToResolveMachPortController
    case failedToResolveKey(String)
    case failedToCreateKeyCode(Int)
    case failedToCreateEvent
  }

  var machPort: MachPortEventController?

  private let store: KeyCodesStore

  internal init(store: KeyCodesStore) {
    self.store = store
  }

  func run(_ command: KeyboardCommand, type: CGEventType, with eventSource: CGEventSource?) throws {
    guard let machPort else {
      throw KeyboardEngineError.failedToResolveMachPortController
    }

    let string = command.keyboardShortcut.key.uppercased()

    guard let key = store.keyCode(for: string, matchDisplayValue: true) else {
      throw KeyboardEngineError.failedToResolveKey(string)
    }

    var flags = CGEventFlags()
    if let modifiers = command.keyboardShortcut.modifiers {
      modifiers.forEach { flags.insert($0.cgModifierFlags) }
    }

    try machPort.post(key, type: type, flags: flags)
  }
}

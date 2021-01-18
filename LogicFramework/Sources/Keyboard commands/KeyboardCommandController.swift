import Combine
import Cocoa
import Foundation
import ModelKit
import Quartz
import Carbon.HIToolbox.Events

public protocol KeyboardCommandControlling {
  /// - Parameter command: A `KeyboardCommand` that should be invoked.
  /// - Returns: A publisher that wraps a result of the run operation.
  func run(_ command: KeyboardCommand,
           type: CGEventType,
           eventSource: CGEventSource?) -> CommandPublisher
}

public enum KeyboardCommandControllingError: Error {
  case failedToRunCommand(KeyboardCommand)
  case failedToCreateEventHandler
}

class KeyboardCommandController: KeyboardCommandControlling {

  let keyCodeMapper: KeyCodeMapping
  var cache = [String: Int]()

  init(keyCodeMapper: KeyCodeMapping) {
    self.keyCodeMapper = keyCodeMapper
    cache = keyCodeMapper.hashTable()
  }

  func run(_ command: KeyboardCommand,
           type: CGEventType,
           eventSource: CGEventSource?) -> CommandPublisher {
    return Future { [weak self] promise in
      var flags = CGEventFlags()

      guard let key = self?.cache[command.keyboardShortcut.key.uppercased()] else {
        promise(.failure(KeyboardCommandControllingError.failedToRunCommand(command)))
        return
      }

      command.keyboardShortcut.modifiers?.forEach { flags.insert($0.cgModifierFlags) }

      if let cgKeyCode = CGKeyCode(exactly: key),
         let newEvent = CGEvent(keyboardEventSource: eventSource,
                                virtualKey: cgKeyCode,
                                keyDown: type == .keyDown) {
        newEvent.flags = flags
        newEvent.post(tap: .cghidEventTap)
        promise(.success(()))
      } else {
        promise(.failure(KeyboardCommandControllingError.failedToRunCommand(command)))
      }
    }.eraseToAnyPublisher()
  }
}

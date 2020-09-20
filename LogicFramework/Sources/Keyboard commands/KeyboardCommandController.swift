import Combine
import Cocoa
import Foundation

public protocol KeyboardCommandControlling {
  /// - Parameter command: A `KeyboardCommand` that should be invoked.
  /// - Returns: A publisher that wraps a result of the run operation.
  func run(_ command: KeyboardCommand) -> CommandPublisher
}

public enum KeyboardCommandControllingError: Error {
  case failedToRunCommand(KeyboardCommand)
  case failedToCreateEventHandler
}

class KeyboardCommandController: KeyboardCommandControlling {

  let keyMapper: KeyCodeMapper
  var cache = [String: Int]()

  init() {
    self.keyMapper = KeyCodeMapper()
    cache = keyMapper.hashTable()
  }

  func run(_ command: KeyboardCommand) -> CommandPublisher {
    return Future { [weak self] promise in
      if let key = self?.cache[command.keyboardShortcut.key.uppercased()],
         let cgKeyCode = CGKeyCode(exactly: key),
         let newEvent = CGEvent(keyboardEventSource: nil,
                                virtualKey: cgKeyCode,
                                keyDown: true) {
        newEvent.post(tap: .cghidEventTap)
        promise(.success(()))
      } else {
        promise(.failure(KeyboardCommandControllingError.failedToRunCommand(command)))
      }
    }.eraseToAnyPublisher()
  }
}

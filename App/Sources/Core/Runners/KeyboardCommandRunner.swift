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

    for _ in 1...iterations {
      for keyboardShortcut in keyboardShortcuts {
        let key = try await resolveKey(for: keyboardShortcut.key)
        let flags =  keyboardShortcut.cgFlags
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

          if keyboardShortcut.key.hasPrefix("F") {
            flags.insert(.maskSecondaryFn)
            // NX_DEVICELCMDKEYMASK
            flags.insert(CGEventFlags(rawValue: 8))
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
    }

    return events
  }

  // MARK: Private methods

  private func resolveKey(for string: String) async throws -> Int {
    let uppercased = string.uppercased()

    if let uppercasedResult = await store.keyCode(for: uppercased, matchDisplayValue: true) {
      return uppercasedResult
    }
    if let stringResult = await store.keyCode(for: string, matchDisplayValue: true) {
      return stringResult
    }

    throw KeyboardCommandRunnerError.failedToResolveKey(string)
  }
}

import Cocoa
import Foundation

@MainActor
final class KeyPressCache {
  private var pressedKeys: Set<Int64> = []

  func noKeysPressed() -> Bool {
    pressedKeys.isEmpty
  }

  func handle(_ event: CGEvent) {
    guard event.getIntegerValueField(.keyboardEventAutorepeat) == 0 else {
      return
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    switch event.type {
    case .keyDown:
      pressedKeys.insert(keyCode)
    case .keyUp:
      pressedKeys.remove(keyCode)
    case .flagsChanged:
      let flags = event.flags
      if flags.isEmpty {
        pressedKeys.removeAll()
      }
    default:
      break
    }
  }
}

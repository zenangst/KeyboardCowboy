import Cocoa
import Foundation

@MainActor
final class KeyPressCache {
  private var pressedKeys: Set<Int64> = []

  func noKeysPressed() -> Bool {
    return pressedKeys.isEmpty
  }

  func handle(_ event: CGEvent) {
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

import CoreGraphics
import MachPortSystem

public extension Keyboard {
  /// Held keys from one tap stream. Feed snapshots from its router's handler
  /// so events tagged by the tap's own poster are excluded.
  struct PressedKeys: Sendable {
    public private(set) var keyCodes: Set<Int64> = []

    public init() {}

    public mutating func handle(_ event: MachPortSystem.EventSnapshot) {
      guard !event.isRepeat else { return }

      switch CGEventType(rawValue: event.typeRawValue) {
      case .keyDown:
        keyCodes.insert(event.keyCode)
      case .keyUp:
        keyCodes.remove(event.keyCode)
      case .flagsChanged where event.flagsRawValue == 0:
        reset()
      default:
        break
      }
    }

    /// Call when the tap stops or is interrupted, before feeding it new events.
    public mutating func reset() {
      keyCodes.removeAll()
    }
  }
}

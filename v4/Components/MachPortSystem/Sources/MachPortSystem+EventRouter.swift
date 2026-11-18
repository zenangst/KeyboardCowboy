import CoreGraphics
import Foundation

public extension MachPortSystem {
  /// Routes events synchronously. Confine each instance to its tap's run loop.
  ///
  /// Identity intentionally follows MachPort's single previous-key slot: a
  /// key-up or repeat reuses the most recent key-down ID, even with overlapping keys.
  final class EventRouter {
    private let syntheticSignature: Int64
    private var previousID: UUID?

    public init(syntheticSignature: Int64) {
      precondition(syntheticSignature != 0, "Synthetic signature must be nonzero")
      self.syntheticSignature = syntheticSignature
    }

    /// Synthetic events bearing this router's signature bypass the handler.
    /// The returned event must be returned to the tap before its callback exits.
    public func route(
      _ event: CGEvent,
      type: CGEventType,
      eventSource: CGEventSource? = nil,
      handler: (InterceptedEvent) -> EventDisposition,
    ) -> CGEvent? {
      if event.getIntegerValueField(.eventSourceUserData) == syntheticSignature {
        return event
      }

      let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) == 1
      let id: UUID
      switch event.type {
      case .keyUp:
        id = previousID ?? UUID()
        previousID = nil
      case .keyDown:
        if isRepeat, let previousID {
          id = previousID
        } else {
          id = UUID()
          previousID = id
        }
      default:
        previousID = nil
        id = UUID()
      }

      let intercepted = InterceptedEvent(
        id: id, event: event, eventSource: eventSource, type: type,
        keyCode: event.getIntegerValueField(.keyboardEventKeycode), isRepeat: isRepeat,
      )
      switch handler(intercepted) {
      case .passThrough: return event
      case let .replace(replacement): return replacement
      case .suppress: return nil
      }
    }

    /// Discard held identity when the tap stops or its state becomes unreliable.
    public func reset() {
      previousID = nil
    }
  }
}

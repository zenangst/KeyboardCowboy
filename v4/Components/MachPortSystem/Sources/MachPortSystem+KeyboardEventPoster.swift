import CoreGraphics

public extension MachPortSystem {
  /// Creates and posts keyboard events tagged for a matching EventRouter.
  final class KeyboardEventPoster {
    public let eventSource: CGEventSource?
    private let syntheticSignature: Int64

    public init(eventSource: CGEventSource?, syntheticSignature: Int64) {
      precondition(syntheticSignature != 0, "Synthetic signature must be nonzero")
      self.eventSource = eventSource
      self.syntheticSignature = syntheticSignature
    }

    public func createEvent(
      keyCode: CGKeyCode,
      action: KeyAction,
      flags: CGEventFlags = [],
      isRepeat: Bool = false,
    ) throws -> CGEvent {
      guard let event = CGEvent(
        keyboardEventSource: eventSource,
        virtualKey: keyCode,
        keyDown: action == .down,
      ) else {
        throw Error.eventCreationFailed
      }
      event.flags = flags
      event.setIntegerValueField(.keyboardEventAutorepeat, value: isRepeat ? 1 : 0)
      event.setIntegerValueField(.eventSourceUserData, value: syntheticSignature)
      return event
    }

    /// Core Graphics does not report whether the posted event was delivered.
    @discardableResult
    public func post(
      keyCode: CGKeyCode,
      action: KeyAction,
      flags: CGEventFlags = [],
      isRepeat: Bool = false,
      tapLocation: CGEventTapLocation = .cghidEventTap,
    ) throws -> CGEvent {
      let event = try createEvent(
        keyCode: keyCode, action: action, flags: flags, isRepeat: isRepeat,
      )
      event.post(tap: tapLocation)
      return event
    }
  }
}

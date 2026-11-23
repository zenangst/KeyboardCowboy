import CoreGraphics

public extension MachPortSystem {
  /// Creates and posts keyboard events tagged for a matching EventRouter.
  final class KeyboardEventPoster {
    public let eventSource: CGEventSource?
    private let syntheticSignature: Int64
    #if DEBUG
    private var testingOperations: TestingOperations?
    #endif

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
      #if DEBUG
      let event: CGEvent? = if let testingOperations {
        testingOperations.create(eventSource, keyCode, action == .down)
      } else {
        CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: action == .down)
      }
      #else
      let event = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: action == .down)
      #endif
      guard let event else {
        throw Error.eventCreationFailed
      }

      event.flags = flags
      event.setIntegerValueField(.keyboardEventAutorepeat, value: isRepeat ? 1 : 0)
      try tag(event)
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
      postEvent(event, tapLocation: tapLocation)
      return event
    }

    /// Posts a flags-changed event. Core Graphics does not report delivery.
    @discardableResult
    public func postFlags(
      _ flags: CGEventFlags,
      tapLocation: CGEventTapLocation = .cghidEventTap,
    ) throws -> CGEvent {
      #if DEBUG
      let event: CGEvent? = if let testingOperations {
        testingOperations.createFlags(eventSource)
      } else {
        CGEvent(source: eventSource)
      }
      #else
      let event = CGEvent(source: eventSource)
      #endif
      guard let event else { throw Error.eventCreationFailed }

      event.type = .flagsChanged
      event.flags = flags
      try tag(event)
      postEvent(event, tapLocation: tapLocation)
      return event
    }

    /// Tags and reposts the same event, including flags-changed events.
    /// This mutates its source-user-data field, as in the legacy MachPort API.
    /// Throws without posting if Core Graphics does not apply the signature.
    @discardableResult
    public func repost(
      _ event: CGEvent,
      tapLocation: CGEventTapLocation = .cghidEventTap,
    ) throws -> CGEvent {
      try tag(event)
      postEvent(event, tapLocation: tapLocation)
      return event
    }

    private func tag(_ event: CGEvent) throws {
      event.setIntegerValueField(.eventSourceUserData, value: syntheticSignature)
      guard event.getIntegerValueField(.eventSourceUserData) == syntheticSignature else {
        throw Error.syntheticTagFailed
      }
    }

    private func postEvent(_ event: CGEvent, tapLocation: CGEventTapLocation) {
      #if DEBUG
      if let testingOperations {
        testingOperations.post(event, tapLocation)
      } else {
        event.post(tap: tapLocation)
      }
      #else
      event.post(tap: tapLocation)
      #endif
    }

    #if DEBUG
    convenience init(
      eventSource: CGEventSource?,
      syntheticSignature: Int64,
      testingOperations: TestingOperations,
    ) {
      self.init(eventSource: eventSource, syntheticSignature: syntheticSignature)
      self.testingOperations = testingOperations
    }
    #endif
  }
}

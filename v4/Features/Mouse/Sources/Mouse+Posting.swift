import CoreGraphics

public extension Mouse {
  enum ClickKind: Sendable {
    case click, doubleClick, rightClick
  }

  enum PostingError: Error {
    case eventPostingUnavailable, eventCreationFailed
  }

  /// Posts one click pair at an AX global screen point. Returns false when
  /// the original pointer cannot be read. Core Graphics does not report delivery.
  @MainActor
  @discardableResult
  static func post(_ kind: ClickKind, at point: CGPoint) async throws -> Bool {
    let source = CGEventSource(stateID: .hidSystemState)
    return try await post(
      kind, at: point,
      pointer: { CGEvent(source: nil)?.location },
      canPost: CGPreflightPostEventAccess,
      makeEvent: { type, point, button in
        CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: point, mouseButton: button)
      },
      send: { $0.post(tap: $1) },
      wait: { try await Task.sleep(for: $0) },
    )
  }

  @MainActor
  internal static func post(
    _ kind: ClickKind, at point: CGPoint,
    pointer: () -> CGPoint?, canPost: () -> Bool,
    makeEvent: (CGEventType, CGPoint, CGMouseButton) -> CGEvent?,
    send: (CGEvent, CGEventTapLocation) -> Void,
    wait: (Duration) async throws -> Void,
  ) async throws -> Bool {
    try Task.checkCancellation()
    guard let original = pointer() else { return false }
    guard canPost() else { throw PostingError.eventPostingUnavailable }

    let right = kind == .rightClick
    let button: CGMouseButton = right ? .right : .left
    guard let down = makeEvent(right ? .rightMouseDown : .leftMouseDown, point, button),
          let up = makeEvent(right ? .rightMouseUp : .leftMouseUp, point, button),
          let restore = makeEvent(.mouseMoved, original, .left) else {
      throw PostingError.eventCreationFailed
    }

    let count: Int64 = kind == .doubleClick ? 2 : 1
    for event in [down, up] {
      event.flags = []
      event.setIntegerValueField(.mouseEventClickState, value: count)
    }
    restore.flags = []

    try Task.checkCancellation()
    send(down, .cghidEventTap)
    defer { send(restore, .cghidEventTap) }
    send(up, .cghidEventTap)
    try await wait(.milliseconds(50))
    return true
  }
}

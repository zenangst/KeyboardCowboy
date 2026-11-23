import CoreGraphics
@testable import MouseFeature
import Testing

@MainActor
@Test(arguments: [
  (Mouse.ClickKind.click, CGEventType.leftMouseDown, CGEventType.leftMouseUp, CGMouseButton.left, Int64(1)),
  (.doubleClick, .leftMouseDown, .leftMouseUp, .left, 2),
  (.rightClick, .rightMouseDown, .rightMouseUp, .right, 1),
])
func mousePostsOneClickPairThenRestores(
  _ kind: Mouse.ClickKind, _ down: CGEventType, _ up: CGEventType, _ button: CGMouseButton, _ count: Int64,
) async throws {
  let target = CGPoint(x: -100, y: 80)
  let original = CGPoint(x: 50, y: 60)
  var buttons: [CGMouseButton] = []
  var sent: [CGEvent] = []
  let posted = try await Mouse.post(kind, at: target, pointer: { original }, canPost: { true }, makeEvent: {
    buttons.append($2)
    let event = CGEvent(mouseEventSource: nil, mouseType: $0, mouseCursorPosition: $1, mouseButton: $2)
    event?.flags = .maskCommand
    return event
  }, send: { event, tap in
    #expect(tap == .cghidEventTap)
    sent.append(event)
  }, wait: {
    #expect($0 == .milliseconds(50))
    #expect(sent.map(\.type) == [down, up])
  })
  #expect(posted)
  #expect(buttons == [button, button, .left])
  #expect(sent.map(\.type) == [down, up, .mouseMoved])
  #expect(sent.map(\.location) == [target, target, original])
  #expect(sent.allSatisfy { $0.flags.isEmpty })
  #expect(sent.prefix(2).map { $0.getIntegerValueField(.mouseEventClickState) } == [count, count])
}

@MainActor
@Test func cancelledMouseWaitStillRestoresPointer() async {
  let original = CGPoint(x: 50, y: 60)
  var locations: [CGPoint] = []
  await #expect(throws: CancellationError.self) {
    try await Mouse.post(.click, at: .zero, pointer: { original }, canPost: { true }, makeEvent: {
      CGEvent(mouseEventSource: nil, mouseType: $0, mouseCursorPosition: $1, mouseButton: $2)
    }, send: { event, _ in locations.append(event.location) }, wait: { _ in throw CancellationError() })
  }
  #expect(locations == [.zero, .zero, original])
}

@MainActor
@Test(arguments: [CGEventType.leftMouseDown, .leftMouseUp, .mouseMoved])
func mouseEventCreationFailureDoesNotPostPartialClick(_ failedType: CGEventType) async {
  await #expect(throws: Mouse.PostingError.eventCreationFailed) {
    try await Mouse.post(.click, at: .zero, pointer: { .zero }, canPost: { true }, makeEvent: {
      guard $0 != failedType else { return nil }
      return CGEvent(mouseEventSource: nil, mouseType: $0, mouseCursorPosition: $1, mouseButton: $2)
    }, send: { _, _ in Issue.record("Unexpected post") }, wait: { _ in Issue.record("Unexpected wait") })
  }
}

@MainActor
@Test func missingPointerDoesNotPostMouseEvents() async throws {
  let posted = try await Mouse.post(.click, at: .zero, pointer: { nil }, canPost: {
    Issue.record("Unexpected permission check")
    return true
  }, makeEvent: { _, _, _ in
    Issue.record("Unexpected event")
    return nil
  }, send: { _, _ in Issue.record("Unexpected post") }, wait: { _ in Issue.record("Unexpected wait") })
  #expect(!posted)
}

@MainActor
@Test func missingPostingPermissionDoesNotCreateOrPostMouseEvents() async {
  await #expect(throws: Mouse.PostingError.eventPostingUnavailable) {
    try await Mouse.post(.click, at: .zero, pointer: { .zero }, canPost: { false }, makeEvent: { _, _, _ in
      Issue.record("Unexpected event creation")
      return nil
    }, send: { _, _ in Issue.record("Unexpected post") }, wait: { _ in Issue.record("Unexpected wait") })
  }
}

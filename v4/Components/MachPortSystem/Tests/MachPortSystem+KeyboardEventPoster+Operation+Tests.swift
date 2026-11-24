import CoreGraphics
@testable import MachPortSystem
import Testing

#if DEBUG
@Test func unicodePostingSendsATaggedPairWithItsUTF16Payload() throws {
  var posted: [(CGEvent, CGEventTapLocation)] = []
  let poster = MachPortSystem.KeyboardEventPoster(
    eventSource: nil,
    syntheticSignature: 12345,
    testingOperations: .init(
      create: { CGEvent(keyboardEventSource: $0, virtualKey: $1, keyDown: $2) },
      post: { posted.append(($0, $1)) },
    ),
  )
  try poster.postUnicode("")
  #expect(posted.isEmpty)
  let text = "Ä🙂"
  try poster.postUnicode(text)
  #expect(posted.map { $0.0.type } == [.keyDown, .keyUp])
  for (event, location) in posted {
    var units = [UInt16](repeating: 0, count: 8)
    var length = 0
    event.keyboardGetUnicodeString(maxStringLength: units.count, actualStringLength: &length, unicodeString: &units)
    #expect(String(decoding: units.prefix(length), as: UTF16.self) == text)
    #expect(event.getIntegerValueField(.eventSourceUserData) == 12345)
    #expect(location == .cghidEventTap)
  }
}

@Test func postingPreservesSequenceAndDestination() throws {
  var posted: [(CGEvent, CGEventTapLocation)] = []
  let poster = MachPortSystem.KeyboardEventPoster(
    eventSource: nil,
    syntheticSignature: 12345,
    testingOperations: .init(
      create: { CGEvent(keyboardEventSource: $0, virtualKey: $1, keyDown: $2) },
      post: { posted.append(($0, $1)) },
    ),
  )
  let down = try poster.post(keyCode: 8, action: .down, flags: .maskCommand, tapLocation: .cgSessionEventTap)
  let up = try poster.post(keyCode: 8, action: .up, flags: .maskCommand, tapLocation: .cghidEventTap)

  #expect(posted.count == 2)
  #expect(posted[0].0 === down && posted[1].0 === up)
  #expect(posted[0].1 == .cgSessionEventTap && posted[1].1 == .cghidEventTap)
  #expect(posted.map { $0.0.type } == [.keyDown, .keyUp])
  #expect(posted.allSatisfy { $0.0.flags == .maskCommand })
}

@Test func creationFailureStopsPostingAfterPartialOutput() throws {
  var creationCount = 0
  var posted: [CGEvent] = []
  let poster = MachPortSystem.KeyboardEventPoster(
    eventSource: nil,
    syntheticSignature: 12345,
    testingOperations: .init(
      create: { source, keyCode, isDown in
        creationCount += 1
        return creationCount == 2 ? nil : CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: isDown)
      },
      post: { event, _ in posted.append(event) },
    ),
  )

  let down = try poster.post(keyCode: 8, action: .down)
  #expect(throws: MachPortSystem.KeyboardEventPoster.Error.eventCreationFailed) {
    try poster.post(keyCode: 8, action: .up)
  }
  #expect(creationCount == 2)
  #expect(posted.count == 1 && posted[0] === down)
}

@Test func repostPreservesCapturedEventAndTagsItBeforePosting() throws {
  var posted: [(CGEvent, CGEventTapLocation)] = []
  var signatureAtPost: Int64?
  var creationCount = 0
  let poster = MachPortSystem.KeyboardEventPoster(
    eventSource: nil,
    syntheticSignature: 12345,
    testingOperations: .init(
      create: { _, _, _ in creationCount += 1; return nil },
      post: {
        signatureAtPost = $0.getIntegerValueField(.eventSourceUserData)
        posted.append(($0, $1))
      },
    ),
  )
  let event = try #require(CGEvent(source: nil))
  event.type = .flagsChanged
  event.flags = .maskShift
  event.setIntegerValueField(.keyboardEventKeycode, value: 56)
  let result = try poster.repost(event, tapLocation: .cgSessionEventTap)
  #expect(result === event)
  #expect(creationCount == 0)
  #expect(posted.count == 1)
  #expect(posted[0].0 === event && posted[0].1 == .cgSessionEventTap)
  #expect(event.type == .flagsChanged && event.flags == .maskShift)
  #expect(event.getIntegerValueField(.keyboardEventKeycode) == 56)
  #expect(event.getIntegerValueField(.eventSourceUserData) == 12345)
  #expect(signatureAtPost == 12345)

  let router = MachPortSystem.EventRouter(syntheticSignature: 12345)
  var called = false
  let routed = router.route(event, type: event.type) { _ in
    called = true
    return .suppress
  }
  #expect(routed === event && !called)
}

@Test func repostRejectsEventsThatCannotBeRetagged() throws {
  var posts = 0
  let poster = MachPortSystem.KeyboardEventPoster(
    eventSource: nil,
    syntheticSignature: 12345,
    testingOperations: .init(
      create: { _, _, _ in nil },
      post: { _, _ in posts += 1 },
    ),
  )
  let event = try #require(CGEvent(source: nil))
  event.setIntegerValueField(.eventSourceUserData, value: 987)
  #expect(throws: MachPortSystem.KeyboardEventPoster.Error.syntheticTagFailed) {
    try poster.repost(event)
  }
  #expect(posts == 0)
}

@Test func flagsPostingUsesSourceTagsAndDestination() throws {
  let source = try #require(CGEventSource(stateID: .privateState))
  var receivedSource: CGEventSource?
  var posted: [(CGEvent, CGEventTapLocation)] = []
  let poster = MachPortSystem.KeyboardEventPoster(
    eventSource: source,
    syntheticSignature: 12345,
    testingOperations: .init(
      create: { _, _, _ in nil },
      createFlags: { receivedSource = $0; return CGEvent(source: $0) },
      post: { posted.append(($0, $1)) },
    ),
  )
  let event = try poster.postFlags(.maskShift, tapLocation: .cgSessionEventTap)
  #expect(receivedSource === source)
  #expect(posted.count == 1)
  #expect(posted[0].0 === event && posted[0].1 == .cgSessionEventTap)
  #expect(event.type == .flagsChanged && event.flags == .maskShift)
  #expect(event.getIntegerValueField(.eventSourceUserData) == 12345)
  let router = MachPortSystem.EventRouter(syntheticSignature: 12345)
  var called = false
  #expect(router.route(event, type: .flagsChanged) { _ in
    called = true
    return .suppress
  } === event)
  #expect(!called)
}

@Test func flagsCreationFailureDoesNotPost() {
  var posts = 0
  let poster = MachPortSystem.KeyboardEventPoster(
    eventSource: nil,
    syntheticSignature: 12345,
    testingOperations: .init(
      create: { _, _, _ in nil },
      createFlags: { _ in nil },
      post: { _, _ in posts += 1 },
    ),
  )
  #expect(throws: MachPortSystem.KeyboardEventPoster.Error.eventCreationFailed) {
    try poster.postFlags(.maskShift)
  }
  #expect(posts == 0)
}
#endif

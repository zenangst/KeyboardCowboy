import CoreGraphics
@testable import MachPortSystem
import Testing

#if DEBUG
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
#endif

import CoreGraphics
import Testing
#if DEBUG
@testable import MachPortSystem
#else
import MachPortSystem
#endif

@Test func tapCreatesPosterWithMatchingSourceAndSignature() throws {
  let tap = MachPortSystem.EventTap(syntheticSignature: 42, handler: { _ in .passThrough })
  let source = try #require(tap.eventSource)
  let poster = try tap.makeKeyboardEventPoster()
  let event = try poster.createEvent(keyCode: 1, action: .down)

  #expect(!tap.isRunning)
  #expect(poster.eventSource === source)
  #expect(event.getIntegerValueField(.eventSourceUserData) == 42)
}

#if DEBUG
@Test func normalAndCaptureTapsBypassOnlyTheirSharedSignature() throws {
  var normalEvents: [CGEventType] = []
  var captureEvents: [CGEventType] = []
  let normal = MachPortSystem.EventTap.Context(
    configuration: .init(), signature: 42,
    handler: { normalEvents.append($0.type); return .passThrough },
    onDisruption: { _ in },
  )
  let capture = MachPortSystem.EventTap.Context(
    configuration: .init(), signature: 42,
    handler: { captureEvents.append($0.type); return .passThrough },
    onDisruption: { _ in },
  )
  var posted: [CGEventType] = []
  let poster = MachPortSystem.KeyboardEventPoster(
    eventSource: normal.eventSource,
    syntheticSignature: 42,
    testingOperations: .init(
      create: { CGEvent(keyboardEventSource: $0, virtualKey: $1, keyDown: $2) },
      post: { event, destination in
        posted.append(event.type)
        #expect(destination == .cghidEventTap)
        #expect(normal.deliver(type: event.type, event: event) === event)
        #expect(capture.deliver(type: event.type, event: event) === event)
      },
    ),
  )

  let physicalKey = try #require(CGEvent(keyboardEventSource: nil, virtualKey: 1, keyDown: true))
  let foreignKey = try #require(CGEvent(keyboardEventSource: nil, virtualKey: 2, keyDown: false))
  foreignKey.setIntegerValueField(.eventSourceUserData, value: 99)
  for event in [physicalKey, foreignKey] {
    _ = normal.deliver(type: event.type, event: event)
    _ = capture.deliver(type: event.type, event: event)
  }

  try poster.post(keyCode: 1, action: .down)
  try poster.postFlags(.maskShift)
  try poster.repost(physicalKey)
  #expect(posted == [.keyDown, .flagsChanged, .keyDown])
  #expect(normalEvents == [.keyDown, .keyUp])
  #expect(captureEvents == [.keyDown, .keyUp])
}
#endif

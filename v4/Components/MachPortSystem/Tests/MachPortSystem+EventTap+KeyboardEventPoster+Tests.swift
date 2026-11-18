import CoreGraphics
import MachPortSystem
import Testing

@Test func tapCreatesPosterWithMatchingSourceAndSignature() throws {
  let tap = MachPortSystem.EventTap(syntheticSignature: 42, handler: { _ in .passThrough })
  let source = try #require(tap.eventSource)
  let poster = try tap.makeKeyboardEventPoster()
  let event = try poster.createEvent(keyCode: 1, action: .down)

  #expect(!tap.isRunning)
  #expect(poster.eventSource === source)
  #expect(event.getIntegerValueField(.eventSourceUserData) == 42)
}

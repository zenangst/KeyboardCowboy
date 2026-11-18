import CoreGraphics
import MachPortSystem
import Testing

@Test func keyboardEventsCarryFieldsAndBypassMatchingRouter() throws {
  let poster = MachPortSystem.KeyboardEventPoster(eventSource: nil, syntheticSignature: 12345)
  let router = MachPortSystem.EventRouter(syntheticSignature: 12345)
  for action in [MachPortSystem.KeyboardEventPoster.KeyAction.down, .up] {
    let event = try poster.createEvent(keyCode: 12, action: action, flags: .maskShift, isRepeat: true)
    #expect(event.type == (action == .down ? .keyDown : .keyUp))
    #expect(event.getIntegerValueField(.keyboardEventKeycode) == 12)
    #expect(event.getIntegerValueField(.keyboardEventAutorepeat) == 1)
    #expect(event.flags == .maskShift)
    #expect(event.getIntegerValueField(.eventSourceUserData) == 12345)
    var called = false
    let result = router.route(event, type: event.type) { _ in
      called = true
      return .suppress
    }
    #expect(result === event)
    #expect(!called)
  }
}

@Test func keyboardEventDefaultsToNonRepeating() throws {
  let poster = MachPortSystem.KeyboardEventPoster(eventSource: nil, syntheticSignature: 12345)
  let event = try poster.createEvent(keyCode: 13, action: .down)
  #expect(event.getIntegerValueField(.keyboardEventAutorepeat) == 0)
  #expect(event.flags.isEmpty)
}

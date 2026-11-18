import CoreGraphics
import Foundation
import MachPortSystem
import Testing

private func key(_ code: CGKeyCode, down: Bool = true, repeating: Bool = false) throws -> CGEvent {
  let event = try #require(CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down))
  event.setIntegerValueField(.keyboardEventAutorepeat, value: repeating ? 1 : 0)
  return event
}

@Test func dispositionsAndEventFields() throws {
  let router = MachPortSystem.EventRouter(syntheticSignature: 12345)
  let event = try key(12)
  let passed = router.route(event, type: .keyDown) { intercepted in
    #expect(intercepted.keyCode == 12)
    #expect(intercepted.type == .keyDown)
    #expect(!intercepted.isRepeat)
    intercepted.event.flags = .maskShift
    return .passThrough
  }
  #expect(passed === event)
  #expect(passed?.flags == .maskShift)
  let replacement = try key(13)
  #expect(router.route(event, type: .keyDown) { _ in .replace(replacement) } === replacement)
  #expect(router.route(event, type: .keyDown) { _ in .suppress } == nil)
}

@Test func identityAndReset() throws {
  let router = MachPortSystem.EventRouter(syntheticSignature: 12345)
  var ids: [UUID] = []
  func send(_ event: CGEvent) {
    _ = router.route(event, type: event.type) { intercepted in
      ids.append(intercepted.id)
      return .passThrough
    }
  }
  send(try key(1))
  send(try key(1, repeating: true))
  send(try key(1, down: false))
  send(try key(2))
  router.reset()
  send(try key(2, down: false))
  #expect(ids.count == 5)
  #expect(ids[0] == ids[1] && ids[1] == ids[2])
  #expect(ids[3] != ids[4])
}

@Test func syntheticEventsBypassHandlerAndIdentity() throws {
  let router = MachPortSystem.EventRouter(syntheticSignature: 12345)
  var ids: [UUID] = []
  let down = try key(1)
  _ = router.route(down, type: .keyDown) { ids.append($0.id); return .passThrough }
  let synthetic = try key(2)
  synthetic.setIntegerValueField(.eventSourceUserData, value: 12345)
  var called = false
  let result = router.route(synthetic, type: .keyDown) { _ in
    called = true
    return .suppress
  }
  let up = try key(1, down: false)
  _ = router.route(up, type: .keyUp) { ids.append($0.id); return .passThrough }
  #expect(result === synthetic)
  #expect(!called)
  #expect(ids.count == 2 && ids[0] == ids[1])
}

@Test func legacySingleSlotAndRepeatWithoutDown() throws {
  let router = MachPortSystem.EventRouter(syntheticSignature: 12345)
  var ids: [UUID] = []
  func send(_ event: CGEvent) {
    _ = router.route(event, type: event.type) { ids.append($0.id); return .passThrough }
  }
  send(try key(1, repeating: true))
  send(try key(1, down: false))
  send(try key(1))
  send(try key(2))
  send(try key(1, down: false))
  send(try key(2, down: false))
  #expect(ids.count == 6)
  #expect(ids[0] == ids[1])
  #expect(ids[2] != ids[3])
  #expect(ids[3] == ids[4])
  #expect(ids[4] != ids[5])
}

import CoreGraphics
import MachPortSystem
import Testing

@Test func snapshotRetainsCapturedValuesAcrossEventMutations() async throws {
  let router = MachPortSystem.EventRouter(syntheticSignature: 12345)
  let event = try #require(CGEvent(keyboardEventSource: nil, virtualKey: 12, keyDown: true))
  event.flags = .maskShift
  event.timestamp = 123456
  event.setIntegerValueField(.keyboardEventAutorepeat, value: 1)
  var captured: MachPortSystem.EventSnapshot?
  _ = router.route(event, type: .keyDown) {
    captured = $0.snapshot()
    return .passThrough
  }
  let snapshot = try #require(captured)
  event.flags = .maskCommand
  event.timestamp = 789
  event.setIntegerValueField(.keyboardEventKeycode, value: 13)

  let fromTask = await Task.detached { snapshot }.value
  #expect(fromTask.id == snapshot.id)
  #expect(fromTask.typeRawValue == CGEventType.keyDown.rawValue)
  #expect(fromTask.keyCode == 12)
  #expect(fromTask.flagsRawValue == CGEventFlags.maskShift.rawValue)
  #expect(fromTask.timestamp == 123456)
  #expect(fromTask.isRepeat)
}

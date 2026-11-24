import CoreGraphics
import KeyboardFeature
import MachPortSystem
import Testing

@Test func duplicateDownsAndUnmatchedUpsDoNotAffectOtherHeldKeys() throws {
  var input = RoutedKeys()
  try input.send(.keyDown, code: 12)
  try input.send(.keyDown, code: 12)
  try input.send(.keyDown, code: 13)
  try input.send(.keyUp, code: 14)
  #expect(input.pressed.keyCodes == [12, 13])
  try input.send(.keyUp, code: 12)
  #expect(input.pressed.keyCodes == [13])
  try input.send(.keyUp, code: 13)
  #expect(input.pressed.keyCodes.isEmpty)
}

@Test func autorepeatAndUnrelatedEventsDoNotChangeHeldKeys() throws {
  var input = RoutedKeys()
  try input.send(.keyDown, code: 12)
  try input.send(.keyUp, code: 12, repeatEvent: true)
  try input.send(.keyDown, code: 13, repeatEvent: true)
  try input.send(.leftMouseDown, code: 12)
  try input.send(.flagsChanged, flags: .maskShift)
  #expect(input.pressed.keyCodes == [12])
  try input.send(.flagsChanged)
  #expect(input.pressed.keyCodes.isEmpty)
}

@Test func theTapRoutersOwnSyntheticEventsNeverReachPressedKeys() throws {
  var input = RoutedKeys()
  try input.send(.keyDown, code: 12)
  try input.send(.keyUp, code: 12, sourceTag: RoutedKeys.signature)
  try input.send(.keyDown, code: 13, sourceTag: RoutedKeys.signature)
  #expect(input.delivered == 1)
  #expect(input.pressed.keyCodes == [12])
}

@Test func resettingAfterATapInterruptionDropsHeldKeysBeforeRoutingResumes() throws {
  var input = RoutedKeys()
  try input.send(.keyDown, code: 12)
  try input.send(.keyDown, code: 13)
  #expect(input.pressed.keyCodes == [12, 13])

  // Model the host resetting the router and its consumer on interruption.
  input.router.reset()
  input.pressed.reset()
  #expect(input.pressed.keyCodes.isEmpty)
  try input.send(.keyDown, code: 12, repeatEvent: true)
  try input.send(.keyUp, code: 13)
  #expect(input.pressed.keyCodes.isEmpty)
  try input.send(.keyDown, code: 14)
  #expect(input.pressed.keyCodes == [14])
}

private struct RoutedKeys {
  static let signature: Int64 = 42
  let router = MachPortSystem.EventRouter(syntheticSignature: signature)
  var pressed = Keyboard.PressedKeys()
  var delivered = 0

  mutating func send(
    _ type: CGEventType, code: CGKeyCode = 0, flags: CGEventFlags = [],
    repeatEvent: Bool = false, sourceTag: Int64 = 0,
  ) throws {
    let event = try #require(CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: type != .keyUp))
    event.type = type
    event.flags = flags
    event.setIntegerValueField(.keyboardEventAutorepeat, value: repeatEvent ? 1 : 0)
    event.setIntegerValueField(.eventSourceUserData, value: sourceTag)
    _ = router.route(event, type: type) { intercepted in
      delivered += 1
      pressed.handle(intercepted.snapshot())
      return .passThrough
    }
  }
}

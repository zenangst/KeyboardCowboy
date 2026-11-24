import Carbon
import CoreGraphics
import Foundation
@testable import HostInput
import IOKit.hidsystem
import KeyboardFeature
import KeyCodeSystem
import MachPortSystem
import Testing

@MainActor
@Test func shortcutCaptureUsesRefreshedBaseLabelsAndPreservesModifierSides() throws {
  let us = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
  let french = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.French")
  let center = NotificationCenter()
  var next = us
  let session = HostInput.KeyboardLayoutSession(center: center) { next }
  let flags: CGEventFlags = [
    .maskShift, .maskCommand, .maskControl, .maskAlternate, .maskAlphaShift,
    .init(
      rawValue: UInt64(
        NX_DEVICELCMDKEYMASK
          | NX_DEVICERCMDKEYMASK
          | NX_DEVICERSHIFTKEYMASK
          | NX_DEVICERALTKEYMASK),
    ),
  ]
  let before = try #require(try capture(kVK_ANSI_Q, flags: flags, using: session))
  #expect(before.key == "q")
  #expect(Set(before.modifiers) == [.rightShift, .leftControl, .rightOption, .leftCommand, .rightCommand, .capsLock])

  next = french
  center.post(name: HostInput.KeyboardLayoutSession.sourceChanged, object: nil)
  let after = try #require(try capture(kVK_ANSI_Q, flags: flags, using: session))
  #expect(after.key == "a")
  #expect(after.modifiers == before.modifiers)
}

@MainActor
@Test func shortcutCaptureKeepsNamedKeysAndRejectsNonRecordingEvents() throws {
  let us = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
  let session = HostInput.KeyboardLayoutSession(center: NotificationCenter()) { us }
  let arrow = try #require(try capture(kVK_LeftArrow, flags: [.maskSecondaryFn, .maskNumericPad], using: session))
  #expect(arrow.key == "←")
  #expect(arrow.modifiers.isEmpty)
  let space = try #require(try capture(kVK_Space, flags: .maskSecondaryFn, using: session))
  #expect(space.key == "Space")
  #expect(space.modifiers == [.function])
  #expect(try capture(kVK_ANSI_Keypad1, flags: .maskNumericPad, using: session)?.key == "#1")
  #expect(try capture(kVK_ANSI_A, type: .keyUp, using: session) == nil)
  #expect(try capture(kVK_ANSI_A, type: .flagsChanged, using: session) == nil)
  #expect(try capture(kVK_ANSI_A, repeated: true, using: session) == nil)
  #expect(try capture(kVK_ANSI_A, tagged: true, using: session) == nil)
  #expect(try capture(128, using: session) == nil)

  let missing = HostInput.KeyboardLayoutSession(center: NotificationCenter()) {
    throw KeyCodeSystem.LookupError.layoutUnavailable
  }
  #expect(try capture(kVK_ANSI_A, using: missing) == nil)
}

@MainActor
private func capture(
  _ code: Int, type: CGEventType = .keyDown, flags: CGEventFlags = [],
  repeated: Bool = false, tagged: Bool = false, using layouts: HostInput.KeyboardLayoutSession,
) throws -> Keyboard.Shortcut? {
  let router = MachPortSystem.EventRouter(syntheticSignature: 42)
  let event = try #require(CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(code), keyDown: type != .keyUp))
  event.type = type
  event.flags = flags
  event.setIntegerValueField(.keyboardEventAutorepeat, value: repeated ? 1 : 0)
  event.setIntegerValueField(.eventSourceUserData, value: tagged ? 42 : 0)
  var result: Keyboard.Shortcut?
  _ = router.route(event, type: type) {
    result = HostInput.captureShortcut(from: $0.snapshot(), layouts: layouts)
    return .passThrough
  }
  return result
}

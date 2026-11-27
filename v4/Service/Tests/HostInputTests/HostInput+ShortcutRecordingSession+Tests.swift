import Carbon
import CoreGraphics
import Foundation
@testable import HostInput
import KeyboardFeature
import KeyCodeSystem
import MachPortSystem
import Testing

@MainActor
@Test func shortcutRecordingStopsAfterOneRoutedShortcutAndNeverSuppressesInput() throws {
  let fixture = try ShortcutRecordingFixture()
  try fixture.start()
  try fixture.start()
  try #require(fixture.routes.count == 1)
  try fixture.send(kVK_ANSI_A, tagged: true)
  try fixture.send(kVK_ANSI_A, repeated: true)
  try fixture.send(128)
  #expect(fixture.shortcuts.isEmpty)
  #expect(fixture.stops == 0)

  try fixture.send(kVK_ANSI_A, flags: .maskShift)
  try fixture.send(kVK_ANSI_B)
  #expect(fixture.shortcuts.map(\.key) == ["a"])
  #expect(fixture.shortcuts.first?.modifiers == [.leftShift])
  #expect(fixture.stops == 1)
}

@MainActor
@Test func shortcutRecordingHandlesEscapeDisruptionAndExplicitStop() throws {
  let fixture = try ShortcutRecordingFixture()
  try fixture.start()
  try fixture.send(kVK_Escape)
  #expect(fixture.cancellations == 1)
  #expect(fixture.shortcuts.isEmpty)

  try fixture.start()
  try fixture.send(kVK_ANSI_A, route: 0)
  fixture.disruptions[0](.timeout)
  #expect(fixture.shortcuts.isEmpty)
  #expect(fixture.stops == 1)
  fixture.disruptions[1](.userInput)
  #expect(fixture.reasons == [.userInput])

  try fixture.start()
  try fixture.send(kVK_Escape, flags: .maskCommand)
  #expect(fixture.shortcuts.map(\.key) == ["⎋"])
  #expect(fixture.shortcuts.first?.modifiers == [.leftCommand])

  try fixture.start()
  fixture.session.stop()
  fixture.session.stop()
  try fixture.send(kVK_ANSI_A)
  #expect(fixture.shortcuts.count == 1)
  #expect(fixture.stops == 4)
}

@MainActor
private final class ShortcutRecordingFixture {
  var routes: [HostInput.TapSession.Handler] = []
  var disruptions: [HostInput.TapSession.DisruptionHandler] = []
  var reasons: [MachPortSystem.EventTap.Disruption] = []
  var shortcuts: [Keyboard.Shortcut] = []
  var cancellations = 0
  var stops = 0
  let layouts: HostInput.KeyboardLayoutSession
  let router = MachPortSystem.EventRouter(syntheticSignature: 42)
  lazy var session = HostInput.ShortcutRecordingSession(
    taps: HostInput.TapSession(signature: 42) { [weak self] config, signature, route, disruption in
      #expect(config.eventMask == 1 << CGEventType.keyDown.rawValue)
      #expect(signature == 42)
      self?.routes.append(route)
      self?.disruptions.append(disruption)
      return .init(start: {}, stop: { [weak self] in self?.stops += 1 }, reload: {},
                   makePoster: { throw MachPortSystem.EventTap.Failure.eventSourceCreationFailed })
    },
    layouts: layouts,
  )

  init() throws {
    let us = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
    layouts = HostInput.KeyboardLayoutSession(center: NotificationCenter()) { us }
  }

  func start() throws {
    try session.start(onShortcut: { [weak self] in self?.shortcuts.append($0) },
                      onDisruption: { [weak self] in self?.reasons.append($0) },
                      onCancel: { [weak self] in self?.cancellations += 1 })
  }

  func send(_ code: Int, flags: CGEventFlags = [], repeated: Bool = false, tagged: Bool = false, route: Int? = nil) throws {
    let event = try #require(CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(code), keyDown: true))
    event.flags = flags
    event.setIntegerValueField(.keyboardEventAutorepeat, value: repeated ? 1 : 0)
    event.setIntegerValueField(.eventSourceUserData, value: tagged ? 42 : 0)
    #expect(router.route(event, type: .keyDown, handler: routes[route ?? routes.count - 1]) === event)
  }
}

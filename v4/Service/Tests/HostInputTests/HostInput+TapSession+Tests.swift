import CoreGraphics
@testable import HostInput
import MachPortSystem
import Testing

@MainActor
@Test func keyboardAndCaptureHaveIndependentLifetimesAndSharedSignature() throws {
  var calls: [String] = []
  var routes: [HostInput.TapSession.Handler] = []
  var signatures: [Int64] = []
  let keyboardMask = MachPortSystem.TapConfiguration.keyboardEventMask
  let mouseMask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue)
    | (1 << CGEventType.leftMouseUp.rawValue) | (1 << CGEventType.leftMouseDragged.rawValue)
  let session = HostInput.TapSession(signature: 42) { config, signature, handler, _ in
    let kind = config.eventMask == keyboardMask ? "keyboard" : "capture"
    #expect(config.eventMask == (kind == "keyboard" ? keyboardMask : keyboardMask | mouseMask))
    routes.append(handler)
    signatures.append(signature)
    return .init(
      start: { calls.append("start \(kind)") },
      stop: { calls.append("stop \(kind)") },
      reload: { calls.append("reload \(kind)") },
      makePoster: { .init(eventSource: nil, syntheticSignature: signature) },
    )
  }
  let flags: HostInput.TapSession.Handler = { _ in calls.append("flags"); return .passThrough }
  let event: HostInput.TapSession.Handler = { _ in calls.append("key"); return .suppress }
  try session.startKeyboard(onFlags: flags, onEvent: event, onDisruption: { _ in })
  try session.startKeyboard(onFlags: flags, onEvent: event, onDisruption: { _ in })
  try session.startCapture(handler: { _ in calls.append("capture"); return .passThrough }, onDisruption: { _ in })
  try #require(routes.count == 2)
  let key = try #require(CGEvent(keyboardEventSource: nil, virtualKey: 1, keyDown: true))
  let router = MachPortSystem.EventRouter(syntheticSignature: 42)
  #expect(router.route(key, type: .flagsChanged, handler: routes[0]) === key)
  #expect(router.route(key, type: .keyDown, handler: routes[0]) == nil)
  #expect(router.route(key, type: .keyDown, handler: routes[1]) === key)
  session.stopCapture()
  #expect(session.keyboardPoster != nil)
  try session.reloadKeyboard()
  session.stopKeyboard()
  #expect(session.keyboardPoster == nil)
  #expect(signatures == [42, 42])
  #expect(calls == ["start keyboard", "start capture", "flags", "key", "capture",
                    "stop capture", "reload keyboard", "stop keyboard"])
}

@MainActor
@Test func tapSessionForwardsDisruptionAndClearsPosterOnFailedRecovery() throws {
  var disruptions: [MachPortSystem.EventTap.Disruption] = []
  var notify: HostInput.TapSession.DisruptionHandler?
  var stops = 0
  let session = HostInput.TapSession(signature: 42) { _, signature, _, onDisruption in
    notify = onDisruption
    return .init(
      start: {},
      stop: { stops += 1 },
      reload: { throw MachPortSystem.EventTap.Failure.enableFailed },
      makePoster: { .init(eventSource: nil, syntheticSignature: signature) },
    )
  }
  try session.startKeyboard(
    onFlags: { _ in .passThrough }, onEvent: { _ in .passThrough },
    onDisruption: { disruptions.append($0) },
  )
  notify?(.timeout)
  #expect(disruptions == [.timeout])
  #expect(session.keyboardPoster != nil)
  #expect(throws: MachPortSystem.EventTap.Failure.enableFailed) { try session.reloadKeyboard() }
  #expect(session.keyboardPoster == nil)
  #expect(stops == 1)
}

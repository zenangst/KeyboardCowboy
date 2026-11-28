import CoreGraphics
import KeyboardTriggers
import MachPortSystem
import Testing

private let key = KeyboardTriggers.Signature(keyCode: 0, flags: CGEventFlags.maskCommand.rawValue)
private let next = KeyboardTriggers.Signature(keyCode: 1, flags: 0)

@Test func dueLeaderReplayBypassesMatchingBeforeTheNextPhysicalKey() throws {
  let stream = EventStream(rules: [.init(workflowID: "leader", signature: key, continuation: [next], leaderKey: true)])
  let press = try stream.key(.keyDown, key, at: .zero)
  #expect(press.match == .partial && press.disposition == .suppress)
  let release = try stream.key(.keyUp, key, at: .milliseconds(50))
  let deadline = try #require(release.leaderReplayDeadline)
  #expect(deadline == .milliseconds(150) && release.disposition == .suppress)
  #expect(stream.claimReplay(at: deadline - .milliseconds(1)) == nil)

  let replay = try #require(stream.claimReplay(at: deadline))
  #expect(replay == key)
  for action in [MachPortSystem.KeyboardEventPoster.KeyAction.down, .up] {
    let event = try stream.poster.createEvent(keyCode: replay.keyCode, action: action, flags: .init(rawValue: replay.flags))
    let routed = stream.route(event, at: deadline)
    #expect(routed.decision == nil && routed.event === event)
    #expect(routed.event?.flags.rawValue == key.flags)
  }
  #expect(stream.claimReplay(at: deadline) == nil)
  let lateContinuation = try stream.key(.keyDown, next, at: deadline)
  #expect(lateContinuation.match == .noMatch && lateContinuation.disposition == .passThrough)
}

@Test func modifierChangesCancelHoldWithoutLosingPhysicalReleasePairing() throws {
  let stream = EventStream(rules: [.init(workflowID: "hold", signature: key, holdDuration: .milliseconds(200))])
  let first = try stream.key(.keyDown, key, at: .zero)
  #expect(first.holdDeadline == .milliseconds(200))
  let flagsChanged = try #require(CGEvent(source: nil))
  flagsChanged.type = .flagsChanged
  #expect(stream.route(flagsChanged, at: .milliseconds(50)).event === flagsChanged)
  #expect(stream.completeHold(at: .milliseconds(200)) == nil)
  let unmodified = KeyboardTriggers.Signature(keyCode: key.keyCode, flags: 0)
  #expect(try stream.key(.keyUp, unmodified, at: .milliseconds(210)).disposition == .suppress)

  let second = try stream.key(.keyDown, key, at: .milliseconds(300))
  let deadline = try #require(second.holdDeadline)
  #expect(try stream.key(.keyDown, key, at: .milliseconds(350), repeating: true).match == .noMatch)
  #expect(stream.completeHold(at: deadline - .milliseconds(1)) == nil)
  #expect(stream.completeHold(at: deadline) == "hold")
  #expect(stream.completeHold(at: deadline) == nil)
  #expect(try stream.key(.keyDown, key, at: deadline, repeating: true).match == .noMatch)
  #expect(try stream.key(.keyUp, unmodified, at: deadline).disposition == .suppress)
}

@Test func releaseFollowUpSurvivesFocusChangeButNotInputStreamReset() throws {
  let stream = EventStream(rules: [.init(workflowID: "peek", signature: key, releaseAfter: .milliseconds(500))])
  #expect(try stream.key(.keyDown, key, at: .zero).match == .exact("peek"))
  stream.frontmost = "other"
  #expect(try stream.key(.keyDown, key, at: .milliseconds(400), repeating: true).match == .noMatch)
  let release = try stream.key(.keyUp, key, at: .milliseconds(501))
  #expect(release.match == .exact("peek") && release.disposition == .suppress)
  #expect(try stream.key(.keyUp, key, at: .milliseconds(502)).match == .noMatch)

  #expect(try stream.key(.keyDown, key, at: .seconds(1)).match == .exact("peek"))
  stream.reset()
  let stale = try stream.key(.keyUp, key, at: .seconds(2))
  #expect(stale.match == .noMatch && stale.disposition == .passThrough)
}

@Test func returningToTheSameAppDoesNotReviveAPendingHold() throws {
  let stream = EventStream(rules: [.init(workflowID: "hold", signature: key, holdDuration: .milliseconds(200))])
  let press = try stream.key(.keyDown, key, at: .zero)
  let deadline = try #require(press.holdDeadline)
  stream.frontmost = "other"
  stream.frontmost = "initial"
  #expect(stream.completeHold(at: deadline) == nil)
  #expect(try stream.key(.keyUp, key, at: deadline).disposition == .suppress)
}

/// Composes the two public APIs with synthetic time, without a tap, posting,
/// workflow dispatch, or asynchronous retention of live events.
private final class EventStream {
  private let router = MachPortSystem.EventRouter(syntheticSignature: 0x4b43)
  let poster = MachPortSystem.KeyboardEventPoster(eventSource: nil, syntheticSignature: 0x4b43)
  private var session: KeyboardTriggers.SequenceSession
  var frontmost: String? = "initial" {
    didSet {
      if oldValue != frontmost { session.invalidateMatchingContext() }
    }
  }

  init(rules: [KeyboardTriggers.Rule]) {
    session = .init(matcher: .init(rules: rules), timeout: .seconds(1))
  }

  func key(
    _ type: CGEventType, _ signature: KeyboardTriggers.Signature, at time: Duration, repeating: Bool = false,
  ) throws -> KeyboardTriggers.Decision {
    let event = try #require(CGEvent(keyboardEventSource: nil, virtualKey: signature.keyCode, keyDown: type == .keyDown))
    event.flags = .init(rawValue: signature.flags)
    event.setIntegerValueField(.keyboardEventAutorepeat, value: repeating ? 1 : 0)
    let result = route(event, at: time)
    let decision = try #require(result.decision)
    #expect((result.event == nil) == (decision.disposition == .suppress))
    return decision
  }

  func route(_ event: CGEvent, at time: Duration) -> (event: CGEvent?, decision: KeyboardTriggers.Decision?) {
    var decision: KeyboardTriggers.Decision?
    let routed = router.route(event, type: event.type) { intercepted in
      let snapshot = intercepted.snapshot()
      if snapshot.typeRawValue == CGEventType.flagsChanged.rawValue {
        session.cancelHold()
        return .passThrough
      }
      guard let signature = KeyboardTriggers.Signature(eventKeyCode: snapshot.keyCode, flags: snapshot.flagsRawValue) else {
        return .passThrough
      }
      if snapshot.typeRawValue == CGEventType.keyUp.rawValue {
        decision = session.releaseDecision(keyCode: signature.keyCode, at: time)
      } else if snapshot.isRepeat {
        decision = session.receiveRepeat(signature, frontmostBundleIdentifier: frontmost)
      } else {
        decision = session.receiveDecision(signature, at: time, frontmostBundleIdentifier: frontmost)
      }
      return decision?.disposition == .suppress ? .suppress : .passThrough
    }
    return (routed, decision)
  }

  func completeHold(at time: Duration) -> String? {
    session.completeHold(at: time, frontmostBundleIdentifier: frontmost)
  }

  func claimReplay(at time: Duration) -> KeyboardTriggers.Signature? {
    session.completeLeaderTap(at: time, frontmostBundleIdentifier: frontmost)
  }

  func reset() {
    router.reset()
    session.reset()
  }
}

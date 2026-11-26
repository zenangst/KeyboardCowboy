import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let a = Triggers.Signature(keyCode: 0, flags: 0)
private let b = Triggers.Signature(keyCode: 1, flags: 0)

@Test(arguments: [false, true])
func releaseFollowUpFiresOnceForTheCompletingKey(passthrough: Bool) {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "peek", signature: a, continuation: [b], passthrough: passthrough,
          releaseAfter: .milliseconds(500)),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: "source") == .partial)
  #expect(session.receive(b, at: .milliseconds(100), frontmostBundleIdentifier: "source") == .exact("peek"))
  #expect(session.receiveRepeat(b, frontmostBundleIdentifier: "target").match == .noMatch)
  #expect(session.releaseDecision(keyCode: a.keyCode, at: .milliseconds(601)).match == .noMatch)
  let release = session.releaseDecision(keyCode: b.keyCode, at: .milliseconds(601))
  #expect(release.match == .exact("peek"))
  #expect(release.disposition == (passthrough ? .passThrough : .suppress))
  #expect(session.releaseDecision(keyCode: b.keyCode, at: .seconds(2)).match == .noMatch)
}

@Test(arguments: ["short", "boundary", "clock rollback", "reset", "new press", "untimed release"])
func cancelledOrIneligibleReleaseDoesNotFireLater(reason: String) {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "peek", signature: a, releaseAfter: .milliseconds(500)),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(a, at: .seconds(1), frontmostBundleIdentifier: nil) == .exact("peek"))
  switch reason {
  case "short", "boundary", "clock rollback":
    let time: Duration = reason == "short" ? .milliseconds(1499) : reason == "boundary" ? .milliseconds(1500) : .zero
    let release = session.releaseDecision(keyCode: a.keyCode, at: time)
    #expect(release.match == .noMatch)
    #expect(release.disposition == .suppress)
  case "reset": session.reset()
  case "new press": _ = session.receive(b, at: .milliseconds(1100), frontmostBundleIdentifier: nil)
  default: #expect(session.release(keyCode: a.keyCode) == .suppress)
  }
  #expect(session.releaseDecision(keyCode: a.keyCode, at: .seconds(2)).match == .noMatch)
}

@Test func scheduledHoldDoesNotAlsoArmRelease() {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "hold", signature: a, holdDuration: .milliseconds(200), releaseAfter: .milliseconds(500)),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: nil).holdDeadline == .milliseconds(200))
  #expect(session.completeHold(at: .milliseconds(200), frontmostBundleIdentifier: nil) == "hold")
  #expect(session.releaseDecision(keyCode: a.keyCode, at: .seconds(1)).match == .noMatch)
}

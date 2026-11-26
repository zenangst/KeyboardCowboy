import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let a = Triggers.Signature(keyCode: 0, flags: 0x100008)
private let b = Triggers.Signature(keyCode: 1, flags: 0)

@Test func suppressedPrefixReleaseKeepsTheSequenceAndSuppressesOnlyOnce() {
  let matcher = Triggers.Matcher(rules: [.init(workflowID: "ab", signature: a, continuation: [b])])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: nil).match == .partial)
  #expect(session.release(keyCode: b.keyCode) == .passThrough)
  #expect(session.release(keyCode: a.keyCode) == .suppress)
  #expect(session.release(keyCode: a.keyCode) == .passThrough)
  #expect(session.receiveDecision(b, at: .milliseconds(100), frontmostBundleIdentifier: nil).match == .exact("ab"))
  #expect(session.release(keyCode: b.keyCode) == .suppress)
}

@Test func timeoutAndAppChangesDoNotForgetSuppressedKeyDowns() {
  let app = "com.example.editor"
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "ab", signature: a, allowedBundleIdentifiers: [app], continuation: [b]),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: app).disposition == .suppress)
  #expect(session.receiveDecision(b, at: .seconds(2), frontmostBundleIdentifier: nil).match == .noMatch)
  #expect(session.release(keyCode: b.keyCode) == .passThrough)
  #expect(session.release(keyCode: a.keyCode) == .suppress)
}

@Test func passthroughAndResetLeaveReleasesUntouched() {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "pass", signature: a, passthrough: true),
    .init(workflowID: "suppress", signature: b),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: nil).disposition == .passThrough)
  #expect(session.release(keyCode: a.keyCode) == .passThrough)
  #expect(session.receiveDecision(b, at: .zero, frontmostBundleIdentifier: nil).disposition == .suppress)
  session.reset()
  #expect(session.release(keyCode: b.keyCode) == .passThrough)
}

import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let leader = Triggers.Signature(keyCode: 0, flags: 0)
private let b = Triggers.Signature(keyCode: 1, flags: 0)
private let c = Triggers.Signature(keyCode: 2, flags: 0)

@Test func heldLeaderCanStartAnotherContinuationAfterACompletedMatch() {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "ab", signature: leader, continuation: [b], leaderKey: true),
    .init(workflowID: "ac", signature: leader, continuation: [c], leaderKey: true),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receiveDecision(leader, at: .zero, frontmostBundleIdentifier: nil).disposition == .suppress)
  #expect(session.receiveRepeat(leader, frontmostBundleIdentifier: nil).match == .noMatch)
  #expect(session.receive(b, at: .milliseconds(50), frontmostBundleIdentifier: nil) == .exact("ab"))
  #expect(session.release(keyCode: b.keyCode) == .suppress)
  #expect(session.receive(c, at: .milliseconds(90), frontmostBundleIdentifier: nil) == .exact("ac"))
  #expect(session.release(keyCode: leader.keyCode) == .suppress)
  #expect(session.receive(b, at: .milliseconds(100), frontmostBundleIdentifier: nil) == .noMatch)
}

@Test(arguments: [99, 100])
func timedLeaderReleaseAllowsOnlyABriefContinuation(milliseconds: Int) {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "ab", signature: leader, continuation: [b], leaderKey: true),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(leader, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  #expect(session.releaseDecision(keyCode: leader.keyCode, at: .milliseconds(50)).disposition == .suppress)
  #expect(session.receive(b, at: .milliseconds(50 + milliseconds), frontmostBundleIdentifier: nil)
    == (milliseconds < 100 ? .exact("ab") : .noMatch))
  #expect(session.receive(b, at: .milliseconds(200), frontmostBundleIdentifier: nil) == .noMatch)
}

@Test func leaderDoesNotSurviveMismatchOrScopeChanges() {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "ab", signature: leader, continuation: [b], leaderKey: true),
    .init(workflowID: "c", signature: c),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(leader, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(c, at: .milliseconds(10), frontmostBundleIdentifier: nil) == .exact("c"))
  #expect(session.receive(b, at: .milliseconds(20), frontmostBundleIdentifier: nil) == .noMatch)
  #expect(session.receive(leader, at: .milliseconds(30), frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(b, at: .milliseconds(40), frontmostBundleIdentifier: "other") == .noMatch)
  #expect(session.release(keyCode: leader.keyCode) == .suppress)
}

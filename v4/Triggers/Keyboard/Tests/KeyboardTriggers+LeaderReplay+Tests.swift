import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let leader = Triggers.Signature(keyCode: 0, flags: 0x100008)
private let next = Triggers.Signature(keyCode: 1, flags: 0)
private let matcher = Triggers.Matcher(rules: [
  .init(workflowID: "sequence", signature: leader, continuation: [next], leaderKey: true),
])

@Test func unusedLeaderBecomesOneReplayAfterItsGraceWindow() {
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(leader, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  #expect(session.completeLeaderTap(at: .milliseconds(25), frontmostBundleIdentifier: nil) == nil)
  let release = session.releaseDecision(keyCode: leader.keyCode, at: .milliseconds(50))
  #expect(release.disposition == .suppress)
  #expect(release.leaderReplayDeadline == .milliseconds(150))
  #expect(session.completeLeaderTap(at: .milliseconds(149), frontmostBundleIdentifier: nil) == nil)
  #expect(session.completeLeaderTap(at: .milliseconds(150), frontmostBundleIdentifier: nil) == leader)
  #expect(session.completeLeaderTap(at: .seconds(1), frontmostBundleIdentifier: nil) == nil)
  #expect(session.receive(next, at: .milliseconds(151), frontmostBundleIdentifier: nil) == .noMatch)
}

@Test(arguments: ["used before release", "used during grace", "app", "mode", "context change", "reset"])
func usedOrInvalidatedLeaderDoesNotReplay(reason: String) {
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(leader, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  if reason == "used before release" {
    #expect(session.receive(next, at: .milliseconds(25), frontmostBundleIdentifier: nil) == .exact("sequence"))
  }
  let release = session.releaseDecision(keyCode: leader.keyCode, at: .milliseconds(50))
  #expect(release.leaderReplayDeadline == (reason == "used before release" ? nil : .milliseconds(150)))
  switch reason {
  case "used during grace":
    #expect(session.receive(next, at: .milliseconds(75), frontmostBundleIdentifier: nil) == .exact("sequence"))
  case "app":
    #expect(session.completeLeaderTap(at: .milliseconds(150), frontmostBundleIdentifier: "other") == nil)
  case "mode":
    #expect(session.completeLeaderTap(at: .milliseconds(150), frontmostBundleIdentifier: nil, enabledModeIDs: ["mode"]) == nil)
  case "context change":
    session.invalidateMatchingContext()
    #expect(session.receive(next, at: .milliseconds(75), frontmostBundleIdentifier: nil) == .noMatch)
  case "reset": session.reset()
  default: break
  }
  #expect(session.completeLeaderTap(at: .seconds(1), frontmostBundleIdentifier: nil) == nil)
}

@Test func sequenceTimeoutCanEndTheReplayGraceEarly() {
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .milliseconds(80))
  #expect(session.receive(leader, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  let release = session.releaseDecision(keyCode: leader.keyCode, at: .milliseconds(50))
  #expect(release.leaderReplayDeadline == .milliseconds(80))
  #expect(session.completeLeaderTap(at: .milliseconds(80), frontmostBundleIdentifier: nil) == leader)
}

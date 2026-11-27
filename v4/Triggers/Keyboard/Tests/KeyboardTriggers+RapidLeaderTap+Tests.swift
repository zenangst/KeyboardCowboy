import Carbon
import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let leader = Triggers.Signature(keyCode: 0, flags: 0x100008)
private let next = Triggers.Signature(keyCode: 1, flags: 0)
private let rule = Triggers.Rule(workflowID: "sequence", signature: leader, continuation: [next], leaderKey: true)

private func session(rules: [Triggers.Rule] = [rule], enabled: Bool = true) -> Triggers.SequenceSession {
  .init(matcher: .init(rules: rules), timeout: .seconds(1), useLegacyRapidLeaderTap: enabled)
}

@Test(arguments: [25, 100, 299])
func rapidLeaderRepressRequestsOnlyOneImmediateReplay(interval: Int) {
  var session = session()
  #expect(session.receive(leader, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  let release = session.releaseDecision(keyCode: leader.keyCode, at: .milliseconds(50))
  #expect(release.leaderReplayDeadline == .milliseconds(150))
  let time = Duration.milliseconds(50 + interval)
  #expect(session.completeLeaderTap(at: time, frontmostBundleIdentifier: nil) == (interval < 100 ? nil : leader))

  let decision = session.receiveDecision(leader, at: time, frontmostBundleIdentifier: nil)
  #expect(decision.match == .noMatch)
  #expect(decision.disposition == .suppress)
  #expect(decision.immediateReplay == leader)
  #expect(session.receiveRepeat(leader, frontmostBundleIdentifier: nil).immediateReplay == nil)
  #expect(session.receive(next, at: time + .milliseconds(1), frontmostBundleIdentifier: nil) == .noMatch)
  let secondRelease = session.releaseDecision(keyCode: leader.keyCode, at: time + .milliseconds(2))
  #expect(secondRelease.disposition == .suppress)
  #expect(secondRelease.leaderReplayDeadline == nil)
  #expect(session.completeLeaderTap(at: .seconds(1), frontmostBundleIdentifier: nil) == nil)
}

@Test(arguments: ["disabled", "escape", "boundary", "reset", "untimed", "no prior release"])
func leaderStillArmsWithoutARecentEligibleRelease(reason: String) {
  var session = session(enabled: reason != "disabled")
  if reason != "no prior release" {
    let keyCode = reason == "escape" ? UInt16(kVK_Escape) : next.keyCode
    _ = session.releaseDecision(keyCode: keyCode, at: .milliseconds(50))
  }
  if reason == "reset" { session.reset() }
  if reason == "untimed" { _ = session.release(keyCode: next.keyCode) }
  let time = Duration.milliseconds(reason == "boundary" ? 350 : 75)
  let decision = session.receiveDecision(leader, at: time, frontmostBundleIdentifier: nil)
  #expect(decision.match == .partial)
  #expect(decision.immediateReplay == nil)
  #expect(session.receive(next, at: time + .milliseconds(1), frontmostBundleIdentifier: nil) == .exact("sequence"))
}

@Test func recentUnrelatedReleaseStillAllowsPassthroughAndHeldPrefixes() {
  for passthrough in [true, false] {
    var session = session(rules: [
      .init(workflowID: "sequence", signature: leader, continuation: [next], passthrough: passthrough,
            holdDuration: passthrough ? nil : .milliseconds(50), leaderKey: true),
    ])
    _ = session.releaseDecision(keyCode: next.keyCode, at: .zero)
    let decision = session.receiveDecision(leader, at: .milliseconds(1), frontmostBundleIdentifier: nil)
    #expect(decision.match == .partial)
    #expect(decision.disposition == (passthrough ? .passThrough : .suppress))
    #expect(decision.immediateReplay == nil)
    #expect(session.receive(next, at: .milliseconds(51), frontmostBundleIdentifier: nil) == .exact("sequence"))
  }
}

@Test func unrelatedReleaseEnablesRapidTapButAValidContinuationWins() {
  var rapid = session()
  _ = rapid.releaseDecision(keyCode: next.keyCode, at: .zero)
  #expect(rapid.receiveDecision(leader, at: .milliseconds(1), frontmostBundleIdentifier: nil).immediateReplay == leader)

  var continuation = session(rules: [
    .init(workflowID: "double", signature: leader, continuation: [leader], leaderKey: true),
  ])
  #expect(continuation.receive(leader, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  _ = continuation.releaseDecision(keyCode: leader.keyCode, at: .milliseconds(1))
  let decision = continuation.receiveDecision(leader, at: .milliseconds(2), frontmostBundleIdentifier: nil)
  #expect(decision.match == .exact("double"))
  #expect(decision.immediateReplay == nil)
}

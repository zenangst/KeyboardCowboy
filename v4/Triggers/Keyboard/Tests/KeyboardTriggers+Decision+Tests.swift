import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let a = Triggers.Signature(keyCode: 0, flags: 0)
private let b = Triggers.Signature(keyCode: 1, flags: 0)
private let c = Triggers.Signature(keyCode: 2, flags: 0)

@Test(arguments: [false, true])
func matchedKeysUseTheRulePassthroughPolicy(passthrough: Bool) {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "sequence", signature: a, continuation: [b], passthrough: passthrough),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  let prefix = session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: nil)
  let completion = session.receiveDecision(b, at: .zero, frontmostBundleIdentifier: nil)
  #expect(prefix.match == .partial)
  #expect(completion.match == .exact("sequence"))
  #expect([prefix.disposition, completion.disposition] == Array(repeating: passthrough ? .passThrough : .suppress, count: 2))
}

@Test func eachKeyUsesTheWinningRuleAndMismatchUsesTheFreshMatch() {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "ab", signature: a, continuation: [b]),
    .init(workflowID: "ac", signature: a, continuation: [c], passthrough: true),
    .init(workflowID: "standalone-a", signature: a, allowedBundleIdentifiers: ["com.example"]),
    .init(workflowID: "standalone-a-global", signature: a, modeIDs: ["mode"], passthrough: true),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: nil).disposition == .passThrough)
  let completion = session.receiveDecision(b, at: .zero, frontmostBundleIdentifier: nil)
  #expect(completion.match == .exact("ab"))
  #expect(completion.disposition == .suppress)

  let unmatched = session.receiveDecision(b, at: .zero, frontmostBundleIdentifier: nil)
  #expect(unmatched.match == .noMatch)
  #expect(unmatched.disposition == .passThrough)

  _ = session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: nil)
  let restart = session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: nil)
  #expect(restart.match == .partial)
  #expect(restart.disposition == .passThrough)

  let standalone = session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: "com.example")
  #expect(standalone.match == .exact("standalone-a"))
  #expect(standalone.disposition == .suppress)
  let mode = session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: "com.example", enabledModeIDs: ["mode"])
  #expect(mode.match == .exact("standalone-a-global"))
  #expect(mode.disposition == .passThrough)
}

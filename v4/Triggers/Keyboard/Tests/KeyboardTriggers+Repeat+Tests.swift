import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let a = Triggers.Signature(keyCode: 0, flags: 0x100008)
private let b = Triggers.Signature(keyCode: 1, flags: 0)

@Test(arguments: [false, true], [false, true])
func repeatsHonorTheCompletedRulesRepeatAndPassthroughSettings(allowRepeat: Bool, passthrough: Bool) {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "ab", signature: a, continuation: [b], passthrough: passthrough, allowRepeat: allowRepeat),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receiveRepeat(a, frontmostBundleIdentifier: nil).match == .noMatch)
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  let prefixRepeat = session.receiveRepeat(a, frontmostBundleIdentifier: nil)
  #expect(prefixRepeat.match == .noMatch)
  #expect(prefixRepeat.disposition == (passthrough ? .passThrough : .suppress))
  #expect(session.receiveRepeat(b, frontmostBundleIdentifier: nil).match == .noMatch)
  #expect(session.receive(b, at: .milliseconds(100), frontmostBundleIdentifier: nil) == .exact("ab"))
  let completionRepeat = session.receiveRepeat(b, frontmostBundleIdentifier: nil)
  #expect(completionRepeat.match == (allowRepeat ? .exact("ab") : .noMatch))
  #expect(completionRepeat.disposition == (passthrough ? .passThrough : .suppress))
  _ = session.release(keyCode: b.keyCode)
  #expect(session.receiveRepeat(b, frontmostBundleIdentifier: nil).match == .noMatch)
  #expect(session.receiveRepeat(b, frontmostBundleIdentifier: nil).disposition == .passThrough)
}

@Test(arguments: ["app", "mode", "flags", "context change", "reset", "new press"])
func repeatAuthorizationDoesNotSurviveInvalidation(reason: String) {
  let matcher = Triggers.Matcher(rules: [.init(workflowID: "a", signature: a)])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: nil) == .exact("a"))
  #expect(session.receiveRepeat(a, frontmostBundleIdentifier: nil).match == .exact("a"))
  switch reason {
  case "app":
    #expect(session.receiveRepeat(a, frontmostBundleIdentifier: "com.example").match == .noMatch)
  case "mode":
    #expect(session.receiveRepeat(a, frontmostBundleIdentifier: nil, enabledModeIDs: ["mode"]).match == .noMatch)
  case "flags":
    #expect(session.receiveRepeat(.init(keyCode: a.keyCode, flags: 0), frontmostBundleIdentifier: nil).match == .noMatch)
  case "context change":
    session.invalidateMatchingContext()
  case "reset":
    session.reset()
  default:
    #expect(session.receive(b, at: .zero, frontmostBundleIdentifier: nil) == .noMatch)
  }
  let repeated = session.receiveRepeat(a, frontmostBundleIdentifier: nil)
  #expect(repeated.match == .noMatch)
  #expect(repeated.disposition == (reason == "reset" ? .passThrough : .suppress))
}

@Test func repeatingAPrefixDoesNotExtendItsTimeout() {
  let matcher = Triggers.Matcher(rules: [.init(workflowID: "ab", signature: a, continuation: [b])])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receiveRepeat(a, frontmostBundleIdentifier: nil).match == .noMatch)
  #expect(session.receive(b, at: .seconds(1), frontmostBundleIdentifier: nil) == .noMatch)
}

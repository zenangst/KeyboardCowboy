import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let a = Triggers.Signature(keyCode: 0, flags: 0)
private let b = Triggers.Signature(keyCode: 1, flags: 0)
private let c = Triggers.Signature(keyCode: 2, flags: 0)

@Test func earlyContinuationRetriesAtTheRootAndHeldContinuationMatchesAtThreshold() {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "held", signature: a, continuation: [b], holdDuration: .seconds(2)),
    .init(workflowID: "plain", signature: b),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(b, at: .milliseconds(1999), frontmostBundleIdentifier: nil) == .exact("plain"))
  #expect(session.release(keyCode: a.keyCode) == .suppress)
  #expect(session.receive(a, at: .seconds(3), frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(b, at: .seconds(5), frontmostBundleIdentifier: nil) == .exact("held"))
}

@Test(arguments: ["release", "modifier", "timeout", "app", "reset"])
func heldPrefixCannotFinishAfterInvalidation(reason: String) {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "held", signature: a, continuation: [b, c], holdDuration: .seconds(1)),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receiveRepeat(a, frontmostBundleIdentifier: nil).disposition == .suppress)
  #expect(session.receive(b, at: .seconds(1), frontmostBundleIdentifier: nil) == .partial)
  let time: Duration = reason == "timeout" ? .seconds(2) : .milliseconds(1100)
  switch reason {
  case "release": #expect(session.release(keyCode: a.keyCode) == .suppress)
  case "modifier": session.cancelHold()
  case "reset": session.reset()
  default: break
  }
  #expect(session.receive(c, at: time, frontmostBundleIdentifier: reason == "app" ? "other" : nil) == .noMatch)
}

@Test func passthroughPrefixDoesNotRequireAHold() {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "plain", signature: a, continuation: [b], passthrough: true, holdDuration: .seconds(1)),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: nil).disposition == .passThrough)
  #expect(session.release(keyCode: a.keyCode) == .passThrough)
  #expect(session.receive(b, at: .milliseconds(10), frontmostBundleIdentifier: nil) == .exact("plain"))
}

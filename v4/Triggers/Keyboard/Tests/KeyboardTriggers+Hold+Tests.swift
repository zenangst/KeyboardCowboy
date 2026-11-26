import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let a = Triggers.Signature(keyCode: 0, flags: 0)
private let b = Triggers.Signature(keyCode: 1, flags: 0)

@Test(arguments: [false, true])
func singleShortcutHoldFiresOnceAtItsDeadline(passthrough: Bool) {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "hold", signature: a, passthrough: passthrough, holdDuration: .milliseconds(200)),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  let down = session.receiveDecision(a, at: .seconds(1), frontmostBundleIdentifier: nil)
  let disposition: Triggers.Decision.Disposition = passthrough ? .passThrough : .suppress
  #expect(down.match == .noMatch)
  #expect(down.disposition == disposition)
  #expect(down.holdDeadline == .milliseconds(1200))
  #expect(session.completeHold(at: .milliseconds(1199), frontmostBundleIdentifier: nil) == nil)
  #expect(session.receiveRepeat(a, frontmostBundleIdentifier: nil).match == .noMatch)
  #expect(session.completeHold(at: .milliseconds(1200), frontmostBundleIdentifier: nil) == "hold")
  #expect(session.completeHold(at: .seconds(2), frontmostBundleIdentifier: nil) == nil)
  #expect(session.receiveRepeat(a, frontmostBundleIdentifier: nil).match == .noMatch)
  #expect(session.release(keyCode: a.keyCode) == disposition)
}

@Test(arguments: ["release", "new press", "app", "mode", "clock", "modifier change", "reset"])
func cancelledHoldCannotFireLater(reason: String) {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "hold", signature: a, holdDuration: .milliseconds(200)),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receiveDecision(a, at: .seconds(1), frontmostBundleIdentifier: nil).holdDeadline != nil)
  switch reason {
  case "release": #expect(session.release(keyCode: a.keyCode) == .suppress)
  case "new press": _ = session.receive(b, at: .milliseconds(1100), frontmostBundleIdentifier: nil)
  case "app": #expect(session.completeHold(at: .milliseconds(1100), frontmostBundleIdentifier: "com.example") == nil)
  case "mode": #expect(session.completeHold(at: .milliseconds(1100), frontmostBundleIdentifier: nil, enabledModeIDs: ["mode"]) == nil)
  case "clock": #expect(session.completeHold(at: .zero, frontmostBundleIdentifier: nil) == nil)
  case "modifier change": session.cancelHold()
  default: session.reset()
  }
  #expect(session.completeHold(at: .seconds(2), frontmostBundleIdentifier: nil) == nil)
  if reason == "modifier change" {
    #expect(session.release(keyCode: a.keyCode) == .suppress)
  }
}

@Test func nonpositiveAndMultiKeyHoldsDoNotScheduleSingleShortcutTimers() {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "immediate", signature: b, holdDuration: .zero),
    .init(workflowID: "sequence", signature: a, continuation: [b], holdDuration: .seconds(1)),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(b, at: .zero, frontmostBundleIdentifier: nil) == .exact("immediate"))
  #expect(session.receiveDecision(a, at: .zero, frontmostBundleIdentifier: nil).holdDeadline == nil)
  let finish = session.receiveDecision(b, at: .zero, frontmostBundleIdentifier: nil)
  #expect(finish.match == .exact("sequence"))
  #expect(finish.holdDeadline == nil)
}

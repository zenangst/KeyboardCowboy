import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let a = Triggers.Signature(keyCode: 0, flags: 0)
private let b = Triggers.Signature(keyCode: 1, flags: 0)
private let c = Triggers.Signature(keyCode: 2, flags: 0)

@Test func sharesPrefixesAndCompletesOnlyMatchingBranches() {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "ab", signature: a, continuation: [b]),
    .init(workflowID: "acb", signature: a, continuation: [c, b]),
  ])
  #expect(matcher.match(a, frontmostBundleIdentifier: nil) == nil)
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(b, at: .milliseconds(700), frontmostBundleIdentifier: nil) == .exact("ab"))
  #expect(session.receive(a, at: .seconds(2), frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(c, at: .milliseconds(2700), frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(b, at: .milliseconds(3400), frontmostBundleIdentifier: nil) == .exact("acb"))
  #expect(session.receive(b, at: .seconds(4), frontmostBundleIdentifier: nil) == .noMatch)
}

@Test func mismatchRetriesTheCurrentKeyAsAnExactOrPartialStart() {
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "ab", signature: a, continuation: [b]),
    .init(workflowID: "c", signature: c),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(c, at: .milliseconds(100), frontmostBundleIdentifier: nil) == .exact("c"))
  #expect(session.receive(a, at: .milliseconds(200), frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(a, at: .milliseconds(300), frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(b, at: .milliseconds(400), frontmostBundleIdentifier: nil) == .exact("ab"))
}

@Test func scopeAndRuleOrderResolveExactPrefixConflicts() {
  let app = "com.example.editor"
  let ordinary = Triggers.Rule(workflowID: "a", signature: a)
  let modeSequence = Triggers.Rule(workflowID: "mode-ab", signature: a, modeIDs: ["mode"], continuation: [b])
  let scopedSequence = Triggers.Rule(workflowID: "app-ab", signature: a, allowedBundleIdentifiers: [app], continuation: [b])
  let globalSequence = Triggers.Rule(workflowID: "ab", signature: a, continuation: [b])
  let matcher = Triggers.Matcher(rules: [scopedSequence, modeSequence, globalSequence, ordinary])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: nil) == .exact("a"))
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: app) == .partial)
  #expect(session.receive(b, at: .milliseconds(100), frontmostBundleIdentifier: app) == .exact("app-ab"))
  #expect(session.receive(a, at: .seconds(1), frontmostBundleIdentifier: app, enabledModeIDs: ["mode"]) == .partial)
  #expect(session.receive(b, at: .milliseconds(1100), frontmostBundleIdentifier: app, enabledModeIDs: ["mode"])
    == .exact("mode-ab"))
  var reversed = Triggers.SequenceSession(matcher: .init(rules: [ordinary, globalSequence]), timeout: .seconds(1))
  #expect(reversed.receive(a, at: .zero, frontmostBundleIdentifier: nil) == .partial)
}

@Test(arguments: ["deadline", "clock reset", "app", "mode", "explicit reset"])
func pendingPrefixDoesNotSurviveInvalidation(reason: String) {
  let matcher = Triggers.Matcher(rules: [.init(workflowID: "ab", signature: a, continuation: [b])])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(a, at: .seconds(1), frontmostBundleIdentifier: nil) == .partial)
  if reason == "explicit reset" { session.reset() }
  let time: Duration = reason == "deadline" ? .seconds(2) : reason == "clock reset" ? .zero : .milliseconds(1100)
  #expect(session.receive(b, at: time, frontmostBundleIdentifier: reason == "app" ? "com.example" : nil,
                          enabledModeIDs: reason == "mode" ? ["mode"] : []) == .noMatch)
}

@Test func sequenceCompilationDoesNotSkipUnresolvedSteps() {
  let compiler = Triggers.Compiler { key, _ in key == "a" ? 0 : key == "b" ? 1 : nil }
  #expect(compiler.signatures(for: [.init(key: "a"), .init(key: "b")])?.map(\.keyCode) == [0, 1])
  #expect(compiler.signatures(for: [.init(key: "a"), .init(key: "unknown"), .init(key: "b")]) == nil)
  #expect(compiler.signatures(for: []) == nil)
}

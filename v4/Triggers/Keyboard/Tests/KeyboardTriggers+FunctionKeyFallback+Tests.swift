import Carbon
import CoreGraphics
import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let fn = CGEventFlags.maskSecondaryFn.rawValue
private let extra: UInt64 = 1 << 63
private let f1 = Triggers.Signature(keyCode: UInt16(kVK_F1), flags: 0)
private let f1WithFn = Triggers.Signature(keyCode: f1.keyCode, flags: fn)
private let a = Triggers.Signature(keyCode: UInt16(kVK_ANSI_A), flags: 0)

@Test func functionKeyFallbackIsOptInAndExactWins() {
  let matcher = Triggers.Matcher(rules: [.init(workflowID: "fn", signature: f1WithFn, modeIDs: ["mode"])])
  var exact = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(exact.receive(f1, at: .zero, frontmostBundleIdentifier: nil, enabledModeIDs: ["mode"]) == .noMatch)
  var legacy = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1), useLegacyFunctionKeyFallback: true)
  #expect(legacy.receive(f1, at: .zero, frontmostBundleIdentifier: nil, enabledModeIDs: ["mode"]) == .exact("fn"))
  let both = Triggers.Matcher(rules: [
    .init(workflowID: "plain", signature: f1),
    .init(workflowID: "fn", signature: f1WithFn, modeIDs: ["mode"]),
  ])
  var preferred = Triggers.SequenceSession(matcher: both, timeout: .seconds(1), useLegacyFunctionKeyFallback: true)
  #expect(preferred.receive(f1, at: .zero, frontmostBundleIdentifier: nil, enabledModeIDs: ["mode"]) == .exact("plain"))
}

@Test func toggledFlagsAreTriedBeforeOriginalKnownFlagsAndOnlyForFunctionKeys() {
  let input = Triggers.Signature(keyCode: f1.keyCode, flags: extra)
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "known", signature: f1),
    .init(workflowID: "toggle", signature: .init(keyCode: f1.keyCode, flags: extra | fn)),
    .init(workflowID: "a", signature: a),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1), useLegacyFunctionKeyFallback: true)
  #expect(session.receive(input, at: .zero, frontmostBundleIdentifier: nil) == .exact("toggle"))
  #expect(session.receive(.init(keyCode: a.keyCode, flags: extra), at: .zero, frontmostBundleIdentifier: nil) == .noMatch)
  var known = Triggers.SequenceSession(matcher: .init(rules: [.init(workflowID: "known", signature: f1)]),
                                       timeout: .seconds(1), useLegacyFunctionKeyFallback: true)
  #expect(known.receive(input, at: .zero, frontmostBundleIdentifier: nil) == .exact("known"))
}

@Test func modeScopedLeaderRetainsItsResolvedPrefixAndRepeatsUseObservedFlags() {
  let f2 = Triggers.Signature(keyCode: UInt16(kVK_F2), flags: 0)
  let f2WithFn = Triggers.Signature(keyCode: f2.keyCode, flags: fn)
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "leader", signature: f1WithFn, allowedBundleIdentifiers: ["app"],
          modeIDs: ["mode"], continuation: [f2WithFn], leaderKey: true),
  ])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1), useLegacyFunctionKeyFallback: true)
  #expect(session.receive(f1, at: .zero, frontmostBundleIdentifier: "app", enabledModeIDs: ["mode"]) == .partial)
  #expect(session.receive(f2, at: .milliseconds(1), frontmostBundleIdentifier: "app", enabledModeIDs: ["mode"])
    == .exact("leader"))
  #expect(session.receiveRepeat(f2, frontmostBundleIdentifier: "app", enabledModeIDs: ["mode"]).match == .exact("leader"))
  #expect(session.release(keyCode: f2.keyCode) == .suppress)
  #expect(session.receive(f2, at: .milliseconds(2), frontmostBundleIdentifier: "app", enabledModeIDs: ["mode"])
    == .exact("leader"))
}

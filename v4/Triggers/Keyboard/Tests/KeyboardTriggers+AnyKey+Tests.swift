import Foundation
import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let a = Triggers.Signature(keyCode: 0, flags: 0)
private let b = Triggers.Signature(keyCode: 1, flags: 0)
private let c = Triggers.Signature(keyCode: 2, flags: 0x100008)

@Test func compilesOnlyUnmodifiedTerminalAnyAfterResolvedPrefix() throws {
  let compiler = Triggers.Compiler { key, _ in key == "a" ? 0 : key == "b" ? 1 : nil }
  let saved = try JSONDecoder().decode([Triggers.SavedShortcut].self,
                                       from: Data(#"[{"key":"a"},{"key":"b"},{"key":"any"}]"#.utf8))
  let compiled = try #require(compiler.sequence(for: saved))
  #expect(compiled.signature.keyCode == 0)
  #expect(compiled.continuation.map(\.keyCode) == [1])
  #expect(compiled.endsWithAnyKey)
  #expect(compiler.sequence(for: Array(saved.dropLast()))?.endsWithAnyKey == false)
  #expect(compiler.sequence(for: [.init(key: "any")]) == nil)
  #expect(compiler.sequence(for: [.init(key: "any"), .init(key: "a")]) == nil)
  #expect(compiler.sequence(for: [.init(key: "unresolved"), .init(key: "any")]) == nil)
  #expect(compiler.sequence(for: [.init(key: "a"), .init(key: "any", modifiers: [.leftShift])]) == nil)
}

@Test func anyKeyConsumesOneInputOnlyAfterItsEntirePrefix() {
  let matcher = Triggers.Matcher(rules: [.init(workflowID: "any", signature: a, continuation: [b], endsWithAnyKey: true)])
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  #expect(session.receive(c, at: .zero, frontmostBundleIdentifier: nil) == .noMatch)
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(c, at: .zero, frontmostBundleIdentifier: nil) == .noMatch)
  #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(b, at: .zero, frontmostBundleIdentifier: nil) == .partial)
  #expect(session.receive(c, at: .zero, frontmostBundleIdentifier: nil) == .exact("any"))
  #expect(session.receive(c, at: .zero, frontmostBundleIdentifier: nil) == .noMatch)
}

@Test func fixedKeyWinsWithinSameScopeButAppScopedAnyBeatsGlobal() {
  let app = "com.example.editor"
  let matcher = Triggers.Matcher(rules: [
    .init(workflowID: "fixed", signature: a, continuation: [b]),
    .init(workflowID: "any", signature: a, endsWithAnyKey: true),
    .init(workflowID: "scoped", signature: a, allowedBundleIdentifiers: [app], endsWithAnyKey: true),
  ])
  #expect(matcher.match(a, frontmostBundleIdentifier: app) == nil)
  var session = Triggers.SequenceSession(matcher: matcher, timeout: .seconds(1))
  for (scope, key, expected) in [(nil, b, "fixed"), (nil, c, "any"), (app, b, "scoped")] {
    #expect(session.receive(a, at: .zero, frontmostBundleIdentifier: scope) == .partial)
    #expect(session.receive(key, at: .zero, frontmostBundleIdentifier: scope) == .exact(expected))
  }
}

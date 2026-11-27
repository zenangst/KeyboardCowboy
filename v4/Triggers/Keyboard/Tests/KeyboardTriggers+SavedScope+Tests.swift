import Foundation
import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let signature = Triggers.Signature(keyCode: 12, flags: 0)
private let editor = "com.example.editor"

private func rule(_ id: String, json: String) throws -> Triggers.Rule {
  let scope = try JSONDecoder().decode(Triggers.SavedScope.self, from: Data(json.utf8))
  return .init(workflowID: id, signature: signature, allowedBundleIdentifiers: scope.allowedBundleIdentifiers,
               disallowedBundleIdentifiers: scope.disallowedBundleIdentifiers)
}

@Test(arguments: [
  #"{}"#,
  #"{"allowedBundleIdentifiers":[]}"#,
  #"{"allowedBundleIdentifiers":["*"]}"#,
  #"{"bundleIdentifiers":[],"allowedBundleIdentifiers":["com.example.editor"]}"#,
])
func omittedEmptyAndWildcardScopesMatchGlobally(json: String) throws {
  let matcher = Triggers.Matcher(rules: [try rule("global", json: json)])
  #expect(matcher.match(signature, frontmostBundleIdentifier: nil) == "global")
  #expect(matcher.match(signature, frontmostBundleIdentifier: "com.example.other") == "global")
}

@Test func legacyScopeFieldTakesPrecedenceAndExclusionsStillApply() throws {
  let scoped = try rule("legacy", json: """
    {"bundleIdentifiers":["com.example.editor","com.example.blocked"],
     "allowedBundleIdentifiers":["*"],
     "disallowedBundleIdentifiers":["com.example.blocked"]}
    """)
  let matcher = Triggers.Matcher(rules: [scoped])
  #expect(matcher.match(signature, frontmostBundleIdentifier: editor) == "legacy")
  #expect(matcher.match(signature, frontmostBundleIdentifier: "com.example.blocked") == nil)
  #expect(matcher.match(signature, frontmostBundleIdentifier: nil) == nil)
}

@Test func mixedWildcardScopeKeepsSpecificPrecedenceAndPerRuleExclusions() throws {
  let mixed = try rule("mixed", json: """
    {"allowedBundleIdentifiers":["*","com.example.editor"],
     "disallowedBundleIdentifiers":["com.example.blocked"]}
    """)
  let later = Triggers.Rule(workflowID: "later", signature: signature)
  let matcher = Triggers.Matcher(rules: [mixed, later])
  #expect(matcher.match(signature, frontmostBundleIdentifier: editor) == "mixed")
  #expect(matcher.match(signature, frontmostBundleIdentifier: "com.example.other") == "later")
  #expect(Triggers.Matcher(rules: [mixed]).match(signature, frontmostBundleIdentifier: "com.example.blocked") == nil)
  #expect(Triggers.Matcher(rules: [later, mixed]).match(signature, frontmostBundleIdentifier: "com.example.blocked") == "later")
}

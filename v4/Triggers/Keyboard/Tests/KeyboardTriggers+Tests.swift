import KeyboardTriggers
import Testing

private typealias Triggers = KeyboardTriggers
private let app = "com.example.editor"
private let shortcut = Triggers.Signature(keyCode: 12, flags: 0x100008)

private func rule(_ id: String, apps: Set<String> = [], excluded: Set<String> = [], modes: Set<String> = [],
                  groupEnabled: Bool = true, workflowEnabled: Bool = true) -> Triggers.Rule {
  .init(workflowID: id, signature: shortcut, allowedBundleIdentifiers: apps,
        disallowedBundleIdentifiers: excluded, modeIDs: modes,
        isGroupEnabled: groupEnabled, isWorkflowEnabled: workflowEnabled)
}

@Test func matchesOnlyTheExactKeyCodeAndModifierBits() {
  let matcher = Triggers.Matcher(rules: [rule("exact")])
  #expect(matcher.match(shortcut, frontmostBundleIdentifier: app) == "exact")
  #expect(matcher.match(.init(keyCode: 13, flags: shortcut.flags), frontmostBundleIdentifier: app) == nil)
  // Right Command and either-side Command are not the bound Left Command signature.
  for flags: UInt64 in [0x100010, 0x100000, 0x900008] {
    #expect(matcher.match(.init(keyCode: shortcut.keyCode, flags: flags), frontmostBundleIdentifier: app) == nil)
  }
  #expect(Triggers.Matcher(rules: []).match(shortcut, frontmostBundleIdentifier: nil) == nil)
}

@Test func appSpecificWinsWithinScopeAndGlobalWorksWithoutAFrontmostApp() {
  let matcher = Triggers.Matcher(rules: [rule("scoped", apps: [app]), rule("global")])
  #expect(matcher.match(shortcut, frontmostBundleIdentifier: app) == "scoped")
  #expect(matcher.match(shortcut, frontmostBundleIdentifier: "com.example.other") == "global")
  #expect(matcher.match(shortcut, frontmostBundleIdentifier: nil) == "global")
  #expect(Triggers.Matcher(rules: [rule("scoped", apps: [app])])
    .match(shortcut, frontmostBundleIdentifier: nil) == nil)
}

@Test func modePriorityComesBeforeAppScopeAndUnscopedModeFallback() {
  let matcher = Triggers.Matcher(rules: [
    rule("ordinary", apps: [app]),
    rule("first-global", modes: ["first"]),
    rule("second-scoped", apps: [app], modes: ["second", "alternate"]),
    rule("second-global", modes: ["second"]),
  ])
  #expect(matcher.match(shortcut, frontmostBundleIdentifier: app, enabledModeIDs: ["first", "second"]) == "first-global")
  #expect(matcher.match(shortcut, frontmostBundleIdentifier: app, enabledModeIDs: ["second", "first"]) == "second-scoped")
  #expect(matcher.match(shortcut, frontmostBundleIdentifier: app, enabledModeIDs: ["alternate"]) == "second-scoped")
  #expect(matcher.match(shortcut, frontmostBundleIdentifier: app, enabledModeIDs: ["unrelated"]) == "ordinary")
}

@Test func lastEligibleRuleWinsAndDisabledRulesDoNotShadowIt() {
  let matcher = Triggers.Matcher(rules: [
    rule("old"), rule("new"), rule("disabled-group", groupEnabled: false), rule("disabled-workflow", workflowEnabled: false),
  ])
  #expect(matcher.match(shortcut, frontmostBundleIdentifier: app) == "new")
}

@Test func appExclusionsApplyOnlyToTheirOwnRules() {
  let matcher = Triggers.Matcher(rules: [
    rule("ordinary"),
    rule("excluded-global", excluded: [app]),
    rule("excluded-scoped-mode", apps: [app], excluded: [app], modes: ["mode"]),
  ])
  #expect(matcher.match(shortcut, frontmostBundleIdentifier: app, enabledModeIDs: ["mode"]) == "ordinary")
  #expect(matcher.match(shortcut, frontmostBundleIdentifier: "com.example.other") == "excluded-global")
  #expect(Triggers.Matcher(rules: [rule("excluded", excluded: [app])])
    .match(shortcut, frontmostBundleIdentifier: app) == nil)
}

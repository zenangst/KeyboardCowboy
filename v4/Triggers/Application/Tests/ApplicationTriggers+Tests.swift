import ApplicationTriggers
import Foundation
import Testing

private typealias Triggers = ApplicationTriggers
private let previousApp = "com.example.previous"
private let currentApp = "com.example.current"

@Test func frontmostTransitionPreservesWildcardSpecificAndResignOrder() {
  let rules: [Triggers.Rule] = [
    .init(workflowID: "resign", bundleIdentifier: previousApp, contexts: [.resignFrontMost]),
    .init(workflowID: "specific", bundleIdentifier: currentApp, contexts: [.frontMost]),
    .init(workflowID: "wildcard-one", bundleIdentifier: Triggers.anyApplication, contexts: [.frontMost]),
    .init(workflowID: "wildcard-two", bundleIdentifier: Triggers.anyApplication, contexts: [.frontMost]),
    .init(workflowID: "specific", bundleIdentifier: currentApp, contexts: [.frontMost]),
  ]

  let matches = Triggers.match(.frontmostApplication(previous: previousApp, current: currentApp), rules: rules)
  #expect(matches.map(\.workflowID) == ["wildcard-one", "wildcard-two", "specific", "specific", "resign"])
  #expect(matches.map(\.bundleIdentifier) == [currentApp, currentApp, currentApp, currentApp, previousApp])
  #expect(matches.map(\.context) == [.frontMost, .frontMost, .frontMost, .frontMost, .resignFrontMost])
}

@Test func wildcardMatchesOnlyFrontmostArrival() {
  let rules: [Triggers.Rule] = [
    .init(workflowID: "wildcard", bundleIdentifier: Triggers.anyApplication, contexts: Set(Triggers.Context.allCases)),
  ]

  #expect(Triggers.match(.runningApplications(previous: [previousApp], current: [currentApp]), rules: rules).isEmpty)
  #expect(Triggers.match(.frontmostApplication(previous: previousApp, current: nil), rules: rules).isEmpty)
  #expect(Triggers.match(.frontmostApplication(previous: nil, current: currentApp), rules: rules).map(\.workflowID)
    == ["wildcard"])
}

@Test func repeatedFrontmostAndMissingAppDoNotGenerateFalseTransitions() {
  let rules: [Triggers.Rule] = [
    .init(workflowID: "activate", bundleIdentifier: currentApp, contexts: [.frontMost]),
    .init(workflowID: "resign", bundleIdentifier: currentApp, contexts: [.resignFrontMost]),
  ]

  #expect(Triggers.match(.frontmostApplication(previous: currentApp, current: currentApp), rules: rules).isEmpty)
  #expect(Triggers.match(.frontmostApplication(previous: nil, current: nil), rules: rules).isEmpty)
  #expect(Triggers.match(.frontmostApplication(previous: nil, current: currentApp), rules: rules).map(\.workflowID)
    == ["activate"])
  #expect(Triggers.match(.frontmostApplication(previous: currentApp, current: nil), rules: rules).map(\.workflowID)
    == ["resign"])
}

@Test func matchingRequiresEnabledGroupWorkflowAndAllRequiredModes() {
  let rules: [Triggers.Rule] = [
    .init(workflowID: "always", bundleIdentifier: currentApp, contexts: [.launched]),
    .init(workflowID: "both", bundleIdentifier: currentApp, contexts: [.launched], requiredModeIDs: ["one", "two"]),
    .init(workflowID: "disabled-group", bundleIdentifier: currentApp, contexts: [.launched], isGroupEnabled: false),
    .init(workflowID: "disabled-workflow", bundleIdentifier: currentApp, contexts: [.launched], isWorkflowEnabled: false),
    .init(workflowID: "different-context", bundleIdentifier: currentApp, contexts: [.frontMost]),
  ]
  let event = Triggers.Transition.runningApplications(previous: [], current: [currentApp])

  #expect(Triggers.match(event, rules: rules, enabledModeIDs: ["one"]).map(\.workflowID) == ["always"])
  #expect(Triggers.match(event, rules: rules, enabledModeIDs: ["one", "two", "extra"]).map(\.workflowID) == ["always", "both"])
}

@Test func runningApplicationChangesMatchFirstLaunchAndLastExitOnly() {
  let rules: [Triggers.Rule] = [
    .init(workflowID: "launch", bundleIdentifier: currentApp, contexts: [.launched]),
    .init(workflowID: "close", bundleIdentifier: currentApp, contexts: [.closed]),
  ]

  #expect(Triggers.match(.runningApplications(previous: [], current: [currentApp, currentApp]), rules: rules)
    .map(\.workflowID) == ["launch"])
  #expect(Triggers.match(.runningApplications(previous: [currentApp], current: [currentApp, currentApp]), rules: rules).isEmpty)
  #expect(Triggers.match(.runningApplications(previous: [currentApp, currentApp], current: [currentApp]), rules: rules).isEmpty)
  #expect(Triggers.match(.runningApplications(previous: [currentApp, currentApp], current: []), rules: rules)
    .map(\.workflowID) == ["close"])
  #expect(Triggers.match(.runningApplications(previous: [previousApp, currentApp], current: [currentApp, previousApp]),
                         rules: rules).isEmpty)
}

@Test func simultaneousChangesPreserveRemovalThenInsertionOrder() {
  let rules = ["A", "B", "C", "D"].map {
    Triggers.Rule(workflowID: $0, bundleIdentifier: $0, contexts: [.closed, .launched])
  }
  let matches = Triggers.match(.runningApplications(previous: ["A", "B"], current: ["D", "C"]), rules: rules)
  #expect(matches.map(\.workflowID) == ["B", "A", "D", "C"])
  #expect(matches.map(\.context) == [.closed, .closed, .launched, .launched])
}

@Test func savedContextValuesRoundTrip() throws {
  let fixture = Data(#"["closed","launched","frontMost","resignFrontMost"]"#.utf8)
  let contexts = try JSONDecoder().decode([Triggers.Context].self, from: fixture)
  #expect(contexts == [.closed, .launched, .frontMost, .resignFrontMost])
  #expect(try JSONEncoder().encode(contexts) == fixture)
}

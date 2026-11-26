import Testing
@testable import UIAutomationFeature

@Test func incompatiblePredicateRejectsCandidateBeforeLaterPredicates() {
  let predicates: [UIAutomation.Predicate] = [
    .init(role: .link, properties: [.title], comparison: .equals, value: "Open"),
    .init(properties: [.title], comparison: .equals, value: "Open"),
  ]
  #expect(!UIAutomation.matches(role: .button, predicates: predicates) { _ in
    Issue.record("An incompatible role should not read properties")
    return "Open"
  })
}

@Test func compatiblePredicatesTryPropertiesUntilFirstMatch() {
  let predicates: [UIAutomation.Predicate] = [
    .init(role: .button, properties: [.identifier, .title], comparison: .equals, value: "open"),
    .init(properties: [.description, .subrole], comparison: .prefix, value: "Open"),
  ]
  var reads: [UIAutomation.Property] = []
  let match = UIAutomation.matches(role: .button, predicates: predicates) { property in
    reads.append(property)
    switch property {
    case .title: return "Open"
    case .description: return "Open document"
    default: return nil
    }
  }
  #expect(match)
  #expect(reads == [.identifier, .title, .description])
}

@Test func comparisonIsCaseSensitive() {
  #expect(UIAutomation.Comparison.contains.matches("Open document", "document"))
  #expect(!UIAutomation.Comparison.contains.matches("Open document", "Document"))
  #expect(UIAutomation.Comparison.suffix.matches("Open document", "ment"))
}

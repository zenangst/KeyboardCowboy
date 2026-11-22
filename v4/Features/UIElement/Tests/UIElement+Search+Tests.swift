import Testing
@testable import UIElementFeature

@Test func incompatiblePredicateRejectsCandidateBeforeLaterPredicates() {
  let predicates: [UIElement.Predicate] = [
    .init(role: "AXLink", properties: [.title], comparison: .equals, value: "Open"),
    .init(properties: [.title], comparison: .equals, value: "Open"),
  ]
  #expect(!UIElement.matches(role: "AXButton", predicates: predicates) { _ in
    Issue.record("An incompatible role should not read properties")
    return "Open"
  })
}

@Test func compatiblePredicatesTryPropertiesUntilFirstMatch() {
  let predicates: [UIElement.Predicate] = [
    .init(role: "AXButton", properties: [.identifier, .title], comparison: .equals, value: "open"),
    .init(properties: [.description, .subrole], comparison: .prefix, value: "Open"),
  ]
  var reads: [UIElement.Property] = []
  let match = UIElement.matches(role: "AXButton", predicates: predicates) { property in
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
  #expect(UIElement.Comparison.contains.matches("Open document", "document"))
  #expect(!UIElement.Comparison.contains.matches("Open document", "Document"))
  #expect(UIElement.Comparison.suffix.matches("Open document", "ment"))
}

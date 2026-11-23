import AccessibilitySystem
import Foundation

public enum UIElement {
  /// Searches descendants of a caller-supplied window in source order.
  /// The result is valid only in the supplied AX session.
  public static func firstMatch(
    in session: AccessibilitySystem.Session,
    under window: AccessibilitySystem.Element,
    predicates: [Predicate],
    budget: AccessibilitySystem.TraversalBudget = .init(),
  ) throws -> AccessibilitySystem.Element? {
    guard !predicates.isEmpty else { return nil }

    return try session.firstElement(
      under: window, includingRoot: false, missingChildren: .skipNoValueOrUnsupported, budget: budget,
    ) { element in
      guard let role = try optional({ try session.read(.role, of: element) }) else { return .prune }

      let matched = try matches(role: role, predicates: predicates) { property in
        try optional(allowNonString: property == .value) { try session.read(property.attribute, of: element) }
      }
      return matched ? .match : .descend
    }
  }

  static func matches(
    role: AccessibilitySystem.Role,
    predicates: [Predicate],
    read: (Property) throws -> String?,
  ) rethrows -> Bool {
    for predicate in predicates {
      // Legacy short circuit: an incompatible predicate rejects this candidate.
      if let expectedRole = predicate.role, role != expectedRole { return false }
      for property in predicate.properties {
        if let candidate = try read(property), predicate.comparison.matches(candidate, predicate.value) {
          return true
        }
      }
    }
    return false
  }

  static func optional<Value>(allowNonString: Bool = false, _ read: () throws -> Value) throws -> Value? {
    do {
      return try read()
    } catch let failure as AccessibilitySystem.Failure
      where failure.kind == .noValue || failure.kind == .attributeUnsupported
      || (allowNonString && failure.kind == .malformedValue) {
      return nil
    }
  }
}

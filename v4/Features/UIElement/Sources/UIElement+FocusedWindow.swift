import AccessibilitySystem

public extension UIElement {
  /// Resolves focus and searches in the same transaction. The application
  /// root must represent the frontmost app, for the legacy fallback only.
  static func firstMatch(
    inFrontmostApplication session: AccessibilitySystem.Session,
    predicates: [Predicate],
    budget: AccessibilitySystem.TraversalBudget = .init(),
  ) throws -> AccessibilitySystem.Element? {
    guard let window = try focusedWindow(inFrontmostApplication: session) else { return nil }
    return try firstMatch(in: session, under: window, predicates: predicates, budget: budget)
  }

  /// The application root must represent the frontmost app for the fallback.
  static func focusedWindow(inFrontmostApplication session: AccessibilitySystem.Session) throws -> AccessibilitySystem.Element? {
    try resolveWindow(
      focus: session.focusedElement,
      ancestor: { focus in
        var current: AccessibilitySystem.Element? = focus
        var visited: Set<AccessibilitySystem.Element> = []
        while let element = current, visited.insert(element).inserted {
          guard visited.count <= 64 else { throw FocusError.ancestorLimitReached }
          if try optional({ try session.read(.role, of: element) }) == .window { return element }
          current = try session.parent(of: element)
        }
        return nil
      },
      fallback: session.focusedWindow,
    )
  }

  enum FocusError: Error {
    case ancestorLimitReached
  }

  internal static func resolveWindow<Element>(
    focus: () throws -> Element,
    ancestor: (Element) throws -> Element?,
    fallback: () throws -> Element?,
  ) throws -> Element? {
    let focused: Element
    do {
      focused = try focus()
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      return try fallback()
    }
    return try ancestor(focused)
  }
}

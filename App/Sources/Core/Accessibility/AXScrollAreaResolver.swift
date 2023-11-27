import AXEssibility
import AppKit
import Foundation

enum AXScrollAreaResolverError: Error {
  case noResult
}

enum AXScrollAreaResolver {
  static func resolveFocusedElement(_ parent: AnyFocusedAccessibilityElement) throws -> CGRect {
    let children = try parent.value(.children, as: [AXUIElement].self)
      .map(AnyAccessibilityElement.init)
    var match: AnyAccessibilityElement?

    match = try? processElement(AnyAccessibilityElement(parent.reference))

    guard let match, let frame = match.frame else {
      throw AXScrollAreaResolverError.noResult
    }

    return frame
  }

  private static func processElement(_ element: AnyAccessibilityElement) throws -> AnyAccessibilityElement? {
    var resolvedElement: AnyAccessibilityElement?
    let children = try element.value(.children, as: [AXUIElement].self)
      .map(AnyAccessibilityElement.init)

    if (try? element.value(.focused, as: Bool.self)) == true {
      return element
    }

    if (try? element.value(.selected, as: Bool.self)) == true {
      return element
    }

    for child in children {
      if let result = try? processElement(child) {
        resolvedElement = result
        break
      }
    }

    return resolvedElement
  }
}

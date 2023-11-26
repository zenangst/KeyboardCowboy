import AXEssibility
import AppKit
import Foundation

enum AXScrollAreaResolverError: Error {
  case noResult
}

enum AXScrollAreaResolver {
  static func resolveFocusedElement(_ parent: AnyFocusedAccessibilityElement) throws -> AnyAccessibilityElement {
    let children = try parent.value(.children, as: [AXUIElement].self)
      .map(AnyAccessibilityElement.init)
    var match: AnyAccessibilityElement?

    for child in children {
      if (try? child.value(.focused, as: Bool.self)) == true {
        match = child
        break
      }
      if (try? child.value(.selected, as: Bool.self)) == true {
        match = child
        break
      }
    }

    guard let match else {
      throw AXScrollAreaResolverError.noResult
    }

    return match
  }
}

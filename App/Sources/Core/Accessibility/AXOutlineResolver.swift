import AXEssibility
import AppKit
import Foundation

enum AXOutlineResolverError: Error {
  case noResult
}

enum AXOutlineResolver {
  static func resolveFocusedElement(_ parent: AnyFocusedAccessibilityElement) throws -> AnyAccessibilityElement {
    let children = try parent.value(.children, as: [AXUIElement].self)
      .map(AnyAccessibilityElement.init)
    var match: AnyAccessibilityElement?
    for child in children {
      guard (try? child.value(.selected, as: Bool.self)) == true else { continue }
      match = child
      break
    }

    guard let match else {
      throw AXOutlineResolverError.noResult
    }

    return match
  }
}

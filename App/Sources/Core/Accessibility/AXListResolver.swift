import AXEssibility
import AppKit
import Foundation

enum AXListResolverError: Error {
  case noResult
}

enum AXListResolver {
  static func resolveFocusedElement(_ parent: AnyFocusedAccessibilityElement) throws -> CGRect {
    var match: AnyAccessibilityElement?
    let groups = try parent.value(.children, as: [AXUIElement].self)
      .map(AnyAccessibilityElement.init)

    for group in groups {
      if let elements = try? group.value(.children, as: [AXUIElement].self), !elements.isEmpty{
        let children = elements.map(AnyAccessibilityElement.init)
        for child in children {
          if (try? child.value(.selected, as: Bool.self)) == true {
            match = child
            break
          }
        }
      } else {
        if (try? group.value(.focused, as: Bool.self)) == true {
          match = group
          break
        }
      }
    }

    guard let match, let frame = match.frame else {
      throw AXListResolverError.noResult
    }

    return frame
  }
}

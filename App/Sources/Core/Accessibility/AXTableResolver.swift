import AXEssibility
import AppKit
import Foundation

enum AXTableResolverError: Error {
  case noResult
}

enum AXTableResolver {
  static func resolveFocusedElement(_ parent: AnyFocusedAccessibilityElement) throws -> CGRect {
    let children: [AnyAccessibilityElement] = try parent.value(.children, as: [AXUIElement].self)
      .map { AnyAccessibilityElement($0, messagingTimeout: parent.messagingTimeout) }
    var match: AnyAccessibilityElement?

    for child in children {
      if (try? child.value(.selected, as: Bool.self)) == true {
        match = child
        break
      }
    }

    guard let match, let frame = match.frame else {
      throw AXTableResolverError.noResult
    }

    return frame
  }
}

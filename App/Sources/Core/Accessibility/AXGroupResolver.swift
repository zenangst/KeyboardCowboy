import AXEssibility
import AppKit
import Foundation

enum AXGroupResolverError: Error {
  case noResult
}

enum AXGroupResolver {
  static func resolveFocusedElement(_ parent: AnyAccessibilityElement) throws -> CGRect {
    let children = try parent.value(.children, as: [AXUIElement].self)
      .map { AnyAccessibilityElement($0, messagingTimeout: parent.messagingTimeout) }
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

    if match == nil {
      match = parent
    }

    guard let match, let frame = match.frame else {
      throw AXGroupResolverError.noResult
    }
    
    return frame
  }
}


import AXEssibility
import AppKit
import Foundation

enum AXCollectionResolverError: Error {
  case noResult
}

enum AXCollectionResolver {
  static func resolveFocusedElement(_ parent: AnyFocusedAccessibilityElement) throws -> CGRect {
    let sections = try parent.value(.children, as: [AXUIElement].self)
      .map { AnyAccessibilityElement($0, messagingTimeout: parent.messagingTimeout) }

    var match: AnyAccessibilityElement?
    for section in sections {
      guard let groups: [AnyAccessibilityElement] = try? section.value(.children, as: [AXUIElement].self)
        .map({ AnyAccessibilityElement($0, messagingTimeout: parent.messagingTimeout) }) else {
          continue
        }

      for group in groups {
        guard let children: [AnyAccessibilityElement] = try? group.value(.children, as: [AXUIElement].self)
          .map({ AnyAccessibilityElement($0, messagingTimeout: parent.messagingTimeout) }) else {
            continue
          }

        for child in children {
          if (try? child.value(.selected, as: Bool.self)) == true {
            match = child
            break
          }
        }
      }
    }

    guard let match, let frame = match.frame else {
      throw AXCollectionResolverError.noResult
    }

    return frame
  }
}

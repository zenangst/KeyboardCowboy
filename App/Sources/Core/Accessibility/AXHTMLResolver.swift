import AXEssibility
import AppKit
import Foundation

enum AXHTMLResolverError: Error {
  case unableToResolveFrame
}

enum AXHTMLResolver {
  static func resolveFocusedElement(_ parent: AnyFocusedAccessibilityElement, snapshot: UserSpace.Snapshot) throws -> CGRect {
    var breadCrumb = ""
    if let result = try processElement(AnyAccessibilityElement(parent.reference), snapshot: snapshot, breadCrumb: &breadCrumb),
       let frame = result.frame {
      return frame
    } else {
      throw AXHTMLResolverError.unableToResolveFrame
    }
  }

  private static func processElement(_ element: AnyAccessibilityElement, 
                                     snapshot: UserSpace.Snapshot,
                                     breadCrumb: inout String) throws -> AnyAccessibilityElement? {
    var resolvedElement: AnyAccessibilityElement?
    let children: [AnyAccessibilityElement] = try element.value(.children, as: [AXUIElement].self)
      .map { AnyAccessibilityElement($0, messagingTimeout: element.messagingTimeout) }

    if children.isEmpty {
      if snapshot.selectedText.isEmpty {
        if (try? element.value(.focused, as: Bool.self)) == true {
          return element
        }

        if (try? element.value(.selected, as: Bool.self)) == true {
          return element
        }
      } else {
        if let value = try? element.value(.value, as: String.self) {
          breadCrumb += value
        }

        if breadCrumb.lowercased().contains(snapshot.selectedText.lowercased()) {
          return element
        }
      }
    }

    for child in children {
      if let result: AnyAccessibilityElement = try processElement(child, snapshot: snapshot, breadCrumb: &breadCrumb) {
        resolvedElement = result
        break
      }
    }

    return resolvedElement
  }
}

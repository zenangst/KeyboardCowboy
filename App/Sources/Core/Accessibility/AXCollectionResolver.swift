import AXEssibility
import AppKit
import Foundation

enum AXCollectionResolverError: Error {
  case noResult
}

enum AXCollectionResolver {
  static func resolveFocusedElement(_ parent: AnyFocusedAccessibilityElement) throws -> AnyAccessibilityElement {
    let sections = try parent.value(.children, as: [AXUIElement].self)
      .map(AnyAccessibilityElement.init)
    var match: AnyAccessibilityElement?
    for section in sections {
      let groups = try? section.value(.children, as: [AXUIElement].self)
        .map(AnyAccessibilityElement.init)
      guard let groups else { continue }

      for group in groups {
        let children = try? group.value(.children, as: [AXUIElement].self)
          .map(AnyAccessibilityElement.init)
        guard let children else { continue }

        for child in children {
          if (try? child.value(.selected, as: Bool.self)) == true {
            match = child
            break
          }
        }
      }
    }

    guard let match else {
      throw AXCollectionResolverError.noResult
    }

    return match
  }
}

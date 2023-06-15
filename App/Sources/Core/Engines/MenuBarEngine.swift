import AXEssibility
import Cocoa

enum MenuBarEngineError: Error {
  case failedToFindFrontmostApplication
  case ranOutOfTokens
  case recursionFailed
}

final class MenuBarEngine {
  init() { }

  func execute(_ command: MenuBarCommand) throws {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      throw MenuBarEngineError.failedToFindFrontmostApplication
    }

    let application = AppAccessibilityElement(frontmostApplication.processIdentifier)
    let menuBar = try application.menuBar()
    let menuItems = try menuBar.menuItems()
    let match = try recursiveSearch(command.tokens, items: menuItems)

    match.performAction(.pick)
  }

  private func recursiveSearch(
    _ tokens: [MenuBarCommand.Token],
    items: [MenuBarItemAccessibilityElement]) throws -> MenuBarItemAccessibilityElement {
      guard let token = tokens.first else { throw MenuBarEngineError.ranOutOfTokens }

      var nextTokens = tokens

      if let matchingItem = find(token, in: items) {
        nextTokens.remove(at: 0)
        if nextTokens.isEmpty {
          return matchingItem
        } else {
          let nextItems = try matchingItem.menuItems()
          return try recursiveSearch(nextTokens, items: nextItems)
        }
      } else {
        for item in items {
          let children = try item.menuItems()
          return try recursiveSearch(nextTokens, items: children)
        }
      }

      throw MenuBarEngineError.recursionFailed
    }

  private func find(_ token: MenuBarCommand.Token, in items: [MenuBarItemAccessibilityElement]) -> MenuBarItemAccessibilityElement? {
    items.first(where: { item in
      switch token {
      case .menuItem(let title):
        return item.title == title
      case .menuItems(let title1, let title2):
        return item.title == title1 || item.title == title2
      }
    })
  }
}

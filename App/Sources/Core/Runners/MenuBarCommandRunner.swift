import AXEssibility
import Cocoa

enum MenuBarCommandRunnerError: Error {
  case failedToFindFrontmostApplication
  case ranOutOfTokens
  case recursionFailed
}

@MainActor
final class MenuBarCommandRunner {
  nonisolated init() { }

  func execute(_ command: MenuBarCommand) async throws {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      throw MenuBarCommandRunnerError.failedToFindFrontmostApplication
    }

    let menuItems = try AppAccessibilityElement(frontmostApplication.processIdentifier)
      .menuBar()
      .menuItems()
    let match = try recursiveSearch(command.tokens, items: menuItems)

    match.performAction(.pick)
  }

  private func recursiveSearch(_ tokens: [MenuBarCommand.Token],
                               items: [MenuBarItemAccessibilityElement]) throws -> MenuBarItemAccessibilityElement {
    guard let token = tokens.first else { throw MenuBarCommandRunnerError.ranOutOfTokens }

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

    throw MenuBarCommandRunnerError.recursionFailed
  }

  private func find(_ token: MenuBarCommand.Token, in items: [MenuBarItemAccessibilityElement]) -> MenuBarItemAccessibilityElement? {
    items.first(where: { item in
      switch token {
      case .menuItem(let title):
        return item.title == title 
        || item.title?.hasPrefix(title) == true
      case .menuItems(let title1, let title2):
        return item.title == title1 
        || item.title == title2
        || item.title?.hasPrefix(title1) == true
        || item.title?.hasPrefix(title2) == true
      }
    })
  }
}

import AXEssibility
import Cocoa

enum MenuBarCommandRunnerError: Error {
  case failedToFindFrontmostApplication
  case ranOutOfTokens
  case recursionFailed
}

@MainActor
final class MenuBarCommandRunner {

  private var previousMatch: MenuBarItemAccessibilityElement?

  nonisolated init() { }

  func execute(_ command: MenuBarCommand, repeatingEvent: Bool) async throws {
    if repeatingEvent, let previousMatch {
      previousMatch.performAction(.pick)
      return
    } else {
      previousMatch = nil
    }

    var runningApplication: NSRunningApplication?
    if let application = command.application {
      if let match = NSRunningApplication.runningApplications(withBundleIdentifier: application.bundleIdentifier).first {
        runningApplication = match
      } else {
        NSWorkspace.shared.open(URL(filePath: application.path))
        try await Task.sleep(for: .seconds(0.1))
      }
    } else {
      runningApplication = NSWorkspace.shared.frontmostApplication
    }

    guard let runningApplication else {
      throw MenuBarCommandRunnerError.failedToFindFrontmostApplication
    }

    if runningApplication.processIdentifier != NSWorkspace.shared.frontmostApplication?.processIdentifier {
      runningApplication.activate()
    }

    let menuItems = try AppAccessibilityElement(runningApplication.processIdentifier)
      .menuBar()
      .menuItems()
    let match = try recursiveSearch(command.tokens, items: menuItems)

    match.performAction(.pick)

    if repeatingEvent {
      previousMatch = match
    }
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
      guard item.isEnabled == true else { return false }

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

import AXEssibility
import Cocoa
import Foundation

enum WindowTiling {
  case left
  case right
  case top
  case bottom
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight
  case center
  case fill
  case arrangeLeftRight
  case arrangeRightLeft
  case arrangeTopBottom
  case arrangeBottomTop
  case arrangeLeftQuarters
  case arrangeRightQuarters
  case arrangeTopQuarters
  case arrangeBottomQuarters
  case arrangeQuarters
  case previousSize
}

final class SystemWindowTilingRunner {

  static func run(_ tiling: WindowTiling, snapshot: UserSpace.Snapshot) async throws {
    guard let runningApplication = NSWorkspace.shared.frontmostApplication else {
      return
    }
    let menuItems = try AppAccessibilityElement(runningApplication.processIdentifier)
      .menuBar()
      .menuItems()

    let initialTokens: [MenuBarCommand.Token]
    let optionalTokens: [MenuBarCommand.Token]
    let windowComparisonCount: Int

    let oldSnapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
    let oldWindows = oldSnapshot.windows.visibleWindowsInStage

    switch tiling {
    case .left:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Left"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 1
    case .right:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Right"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 1
    case .top:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Top"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 1
    case .bottom:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Bottom"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 1
    case .topLeft:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Top Left"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 1
    case .topRight:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Top Right"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 1
    case .bottomLeft:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Bottom Left"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 1
    case .bottomRight:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Bottom Right"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 1
    case .center:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Center"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 1
    case .fill:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Center"),
      ]
      windowComparisonCount = 1
    case .arrangeLeftRight:
      if oldWindows.count == 1 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Fill")
        ]
      } else {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Left & Right")
        ]
      }

      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 2
    case .arrangeRightLeft:
      if oldWindows.count == 1 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Fill")
        ]
      } else {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Right & Left")
        ]
      }

      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 2
    case .arrangeTopBottom:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Top & Bottom"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 2
    case .arrangeBottomTop:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Bottom & Top"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 2
    case .arrangeLeftQuarters:
      if oldWindows.count == 1 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Fill")
        ]
      } else if oldWindows.count == 2 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Left & Right"),
        ]
      } else {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Left & Quarters"),
        ]
      }

      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 3
    case .arrangeRightQuarters:
      if oldWindows.count == 1 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Fill"),
        ]
      } else if oldWindows.count == 2 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Right & Left"),
        ]
      } else {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Right & Quarters")
        ]
      }

      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 3
    case .arrangeTopQuarters:
      if oldWindows.count == 1 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Fill"),
        ]
      } else if oldWindows.count == 2 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Top & Bottom")
        ]
      } else {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Top & Quarters"),
        ]
      }
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 3
    case .arrangeBottomQuarters:
      if oldWindows.count == 1 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Fill"),
        ]
      } else if oldWindows.count == 2 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Bottom & Top")
        ]
      } else {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Bottom & Quarters"),
        ]
      }

      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 3
    case .arrangeQuarters:
      if oldWindows.count == 1 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Fill"),
        ]
      } else if oldWindows.count == 2 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Left & Right"),
        ]
      } else if oldWindows.count == 3 {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Left & Quarters"),
        ]
      } else {
        initialTokens = [
          .menuItem(name: "Window"),
          .menuItem(name: "Move & Resize"),
          .menuItem(name: "Quarters")
        ]
      }

      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Fill"),
      ]
      windowComparisonCount = 4
    case .previousSize:
      initialTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Return to Previous Size"),
      ]
      optionalTokens = [
        .menuItem(name: "Window"),
        .menuItem(name: "Move & Resize"),
        .menuItem(name: "Return to Previous Size"),
      ]
      windowComparisonCount = 1
    }

    try await MainActor.run {
      let match = try recursiveSearch(initialTokens, items: menuItems)
      match.performAction(.pick)
    }

    try await Task.sleep(for: .milliseconds(100))

    let newSnapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
    let newWindows = newSnapshot.windows.visibleWindowsInStage.prefix(windowComparisonCount)

    let oldRects = oldWindows
      .prefix(windowComparisonCount)
      .map { $0.rect }
    let newRects = newWindows.map { $0.rect }

    if oldRects == newRects {
      try await MainActor.run {
        let match = try recursiveSearch(optionalTokens, items: menuItems)
        match.performAction(.pick)
      }
    }

  }

  private static func recursiveSearch(_ tokens: [MenuBarCommand.Token],
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

  private static func find(_ token: MenuBarCommand.Token, in items: [MenuBarItemAccessibilityElement]) -> MenuBarItemAccessibilityElement? {
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

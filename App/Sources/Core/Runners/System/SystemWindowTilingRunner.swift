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
  case zoom
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
  @MainActor
  private static var currentTask: Task<Void, any Error>?
  private static let tilingWindowSpacingKey: String = "TiledWindowSpacing"

  static func run(_ tiling: WindowTiling, snapshot: UserSpace.Snapshot) async throws {
    guard let runningApplication = NSWorkspace.shared.frontmostApplication else {
      return
    }

    await currentTask?.cancel()

    let menuItems = try AppAccessibilityElement(runningApplication.processIdentifier)
      .menuBar()
      .menuItems()
    let initialTokens: [MenuBarCommand.Token]
    let oldSnapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
    let oldWindows = oldSnapshot.windows.visibleWindowsInStage

    switch tiling {
    case .left:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left")]
    case .right:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Right")]
    case .top:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top")]
    case .bottom:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom")]
    case .topLeft:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top Left")]
    case .topRight:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top Right")]
    case .bottomLeft:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom Left")]
    case .bottomRight:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom Right")]
    case .center:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Center")]
    case .fill:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Fill")]
    case .zoom:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Zoom")]
    case .arrangeLeftRight:
      if oldWindows.count == 1 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Fill")]
      } else {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left & Right")]
      }
    case .arrangeRightLeft:
      if oldWindows.count == 1 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Fill")]
      } else {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Right & Left")]
      }
    case .arrangeTopBottom:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top & Bottom")]
    case .arrangeBottomTop:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom & Top")]
    case .arrangeLeftQuarters:
      if oldWindows.count == 1 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Fill")]
      } else if oldWindows.count == 2 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left & Right")]
      } else {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left & Quarters")]
      }

    case .arrangeRightQuarters:
      if oldWindows.count == 1 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Fill")]
      } else if oldWindows.count == 2 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Right & Left")]
      } else {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Right & Quarters")]
      }
    case .arrangeTopQuarters:
      if oldWindows.count == 1 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Fill")]
      } else if oldWindows.count == 2 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top & Bottom")]
      } else {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top & Quarters")]
      }
    case .arrangeBottomQuarters:
      if oldWindows.count == 1 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Fill")]
      } else if oldWindows.count == 2 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom & Top")]
      } else {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom & Quarters")]
      }
    case .arrangeQuarters:
      if oldWindows.count == 1 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Fill")]
      } else if oldWindows.count == 2 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left & Right")]
      } else if oldWindows.count == 3 {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left & Quarters")]
      } else {
        initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Quarters")]
      }
    case .previousSize:
      initialTokens = [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Return to Previous Size")]
    }

    await MainActor.run {
      currentTask?.cancel()
      currentTask = Task { @MainActor in
        try Task.checkCancellation()
        let match = try recursiveSearch(initialTokens, items: menuItems)
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

extension UserDefaults: @unchecked @retroactive Sendable { }

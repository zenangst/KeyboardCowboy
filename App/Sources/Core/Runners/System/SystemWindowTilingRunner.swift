import AXEssibility
import Cocoa
import Foundation
import Windows

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
  nonisolated(unsafe) static var debug: Bool = false
  @MainActor private static var currentTask: Task<Void, any Error>?
  @MainActor private static var storage = [WindowModel.WindowNumber: TileStorage]()
  private static let tilingWindowSpacingKey: String = "TiledWindowSpacing"

  static func initialIndex() {
    Task {
      let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
      for screen in NSScreen.screens {
        let visibleScreenFrame = screen.visibleFrame
        let newWindows = snapshot.windows.visibleWindowsInStage
        await determineTiling(for: newWindows, in: visibleScreenFrame, newWindows: newWindows)
      }
    }
  }

  static func run(_ tiling: WindowTiling, snapshot: UserSpace.Snapshot) async throws {
    guard let screen = NSScreen.main, let runningApplication = NSWorkspace.shared.frontmostApplication else {
      return
    }

    let visibleScreenFrame = screen.visibleFrame

    await currentTask?.cancel()

    let oldSnapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
    let oldWindows = oldSnapshot.windows.visibleWindowsInStage
      .filter { $0.rect.intersects(visibleScreenFrame) }

    guard let nextWindow = oldWindows.first else { return }

    let app: AppAccessibilityElement
    if nextWindow.ownerPid.rawValue != runningApplication.processIdentifier {
      let pid = pid_t(nextWindow.ownerPid.rawValue)
      app = AppAccessibilityElement(pid)
      let nextApp = NSRunningApplication(processIdentifier: pid)
      nextApp?.activate(options: .activateIgnoringOtherApps)
    } else {
      app = AppAccessibilityElement(runningApplication.processIdentifier)
    }

    let menuItems = try app
      .menuBar()
      .menuItems()

    let tokens: [MenuBarCommand.Token]
    let updateSubjects: [WindowModel]

    switch tiling {
    case .left:
      tokens = tiling.tokens
      await store(.left, tokens: tokens, for: nextWindow)
      updateSubjects = []
    case .right:
      tokens = tiling.tokens
      await store(.right, tokens: tokens, for: nextWindow)
      updateSubjects = []
    case .top:
      tokens = tiling.tokens
      await store(.top, tokens: tokens, for: nextWindow)
      updateSubjects = []
    case .bottom:
      tokens = tiling.tokens
      await store(.bottom, tokens: tokens, for: nextWindow)
      updateSubjects = []
    case .topLeft:
      tokens = tiling.tokens
      await store(.topLeft, tokens: tokens, for: nextWindow)
      updateSubjects = []
    case .topRight:
      tokens = tiling.tokens
      await store(.topRight, tokens: tokens, for: nextWindow)
      updateSubjects = []
    case .bottomLeft:
      tokens = tiling.tokens
      await store(.bottomLeft, tokens: tokens, for: nextWindow)
      updateSubjects = []
    case .bottomRight:
      tokens = MenuBarCommand.Token.bottomRight()
      await store(.bottomRight, tokens: tokens, for: nextWindow)
      updateSubjects = []
    case .center:
      tokens = MenuBarCommand.Token.center()
      updateSubjects = []
    case .fill:
      tokens = MenuBarCommand.Token.fill()
      updateSubjects = []
    case .zoom:
      tokens = MenuBarCommand.Token.zoom()
      await store(nil, for: nextWindow)
      updateSubjects = []
    case .arrangeLeftRight:
      if oldWindows.count == 1 {
        tokens = MenuBarCommand.Token.fill()
      } else if oldWindows.count >= 2 {
        tokens = MenuBarCommand.Token.leftRight()
        await store(.left, tokens: MenuBarCommand.Token.left(), for: oldWindows[0])
        await store(.right, tokens: MenuBarCommand.Token.right(), for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      } else {
        return
      }
      updateSubjects = []
    case .arrangeRightLeft:
      if oldWindows.count == 1 {
        tokens = MenuBarCommand.Token.fill()
      } else if oldWindows.count >= 2 {
        tokens = MenuBarCommand.Token.rightLeft()
        await store(.right, tokens: MenuBarCommand.Token.right(), for: oldWindows[0])
        await store(.left, tokens: MenuBarCommand.Token.left(), for: oldWindows[1])
        for x in 0...2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      } else {
        return
      }
      updateSubjects = []
    case .arrangeTopBottom:
      if oldWindows.count == 1 {
        tokens = MenuBarCommand.Token.fill()
      } else if oldWindows.count >= 2 {
        tokens = MenuBarCommand.Token.topBottom()
        await store(.top, tokens: MenuBarCommand.Token.top(), for: oldWindows[0])
        await store(.bottom, tokens: MenuBarCommand.Token.bottom(), for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      } else {
        return
      }
      updateSubjects = []
    case .arrangeBottomTop:
      if oldWindows.count == 1 {
        tokens = MenuBarCommand.Token.fill()
      } else if oldWindows.count >= 2 {
        tokens = MenuBarCommand.Token.bottomTop()
        await store(.bottom, tokens: MenuBarCommand.Token.bottom(), for: oldWindows[0])
        await store(.top, tokens: MenuBarCommand.Token.top(), for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      } else {
        return
      }
      updateSubjects = []
    case .arrangeLeftQuarters:
      if oldWindows.count == 1 {
        tokens = MenuBarCommand.Token.fill()
        updateSubjects = []
      } else if oldWindows.count == 2 {
        tokens = MenuBarCommand.Token.leftRight()
        await store(.left, tokens: MenuBarCommand.Token.left(), for: oldWindows[0])
        await store(.right, tokens: MenuBarCommand.Token.right(), for: oldWindows[1])
        updateSubjects = []
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      } else if oldWindows.count >= 3 {
        tokens = tiling.tokens
        await store(.left, tokens: MenuBarCommand.Token.left(), for: oldWindows[0])
        await store(.bottomRight, tokens: MenuBarCommand.Token.bottomRight(), for: oldWindows[1])
        await store(.topRight, tokens: MenuBarCommand.Token.topRight(), for: oldWindows[2])
        updateSubjects = Array(oldWindows[1...2])
        for x in 0..<3 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      } else {
        return
      }
    case .arrangeRightQuarters:
      if oldWindows.count == 1 {
        tokens = MenuBarCommand.Token.fill()
        updateSubjects = []
      } else if oldWindows.count == 2 {
        tokens = MenuBarCommand.Token.rightLeft()
        await store(.top, tokens: MenuBarCommand.Token.right(), for: oldWindows[0])
        await store(.left, tokens: MenuBarCommand.Token.left(), for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = []
      } else if oldWindows.count >= 3 {
        tokens = tiling.tokens
        await store(.right, tokens: MenuBarCommand.Token.right(), for: oldWindows[0])
        await store(.topLeft, tokens: MenuBarCommand.Token.topLeft(), for: oldWindows[2])
        await store(.bottomLeft, tokens: MenuBarCommand.Token.bottomLeft(), for: oldWindows[1])
        for x in 0..<3 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = Array(oldWindows[1..<3])
      } else {
        return
      }
    case .arrangeTopQuarters:
      if oldWindows.count == 1 {
        tokens = MenuBarCommand.Token.fill()
        updateSubjects = []
      } else if oldWindows.count == 2 {
        tokens = MenuBarCommand.Token.topBottom()
        await store(.top, tokens: MenuBarCommand.Token.top(), for: oldWindows[0])
        await store(.bottom, tokens: MenuBarCommand.Token.bottom(), for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = []
      } else if oldWindows.count >= 3 {
        tokens = tiling.tokens
        await store(.top, tokens: MenuBarCommand.Token.top(), for: oldWindows[0])
        await store(.bottomRight, tokens: MenuBarCommand.Token.bottomRight(), for: oldWindows[1])
        await store(.bottomLeft, tokens: MenuBarCommand.Token.bottomLeft(), for: oldWindows[2])
        for x in 0..<3 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = Array(oldWindows[1..<3])
      } else {
        return
      }
    case .arrangeBottomQuarters:
      if oldWindows.count == 1 {
        tokens = MenuBarCommand.Token.fill()
        updateSubjects = []
      } else if oldWindows.count == 2 {
        tokens = MenuBarCommand.Token.bottomTop()
        await store(.bottom, tokens: MenuBarCommand.Token.bottom(), for: oldWindows[0])
        await store(.top, tokens: MenuBarCommand.Token.top(), for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = []
      } else if oldWindows.count >= 3 {
        tokens = tiling.tokens
        await store(.bottom, tokens: MenuBarCommand.Token.bottom(), for: oldWindows[0])
        await store(.topLeft, tokens: MenuBarCommand.Token.topLeft(), for: oldWindows[2])
        await store(.topRight, tokens: MenuBarCommand.Token.topRight(), for: oldWindows[1])
        for x in 0..<3 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = Array(oldWindows[1..<3])
      } else {
        return
      }
    case .arrangeQuarters:
      if oldWindows.count == 1 {
        tokens = MenuBarCommand.Token.fill()
        updateSubjects = []
      } else if oldWindows.count == 2 {
        tokens = MenuBarCommand.Token.leftRight()
        await store(.left, tokens: MenuBarCommand.Token.left(), for: nextWindow)
        await store(.right, tokens: MenuBarCommand.Token.right(), for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = []
      } else if oldWindows.count == 3 {
        tokens = MenuBarCommand.Token.leftQuarters()
        await store(.left, tokens: MenuBarCommand.Token.left(), for: nextWindow)
        await store(.topRight, tokens: MenuBarCommand.Token.topRight(), for: oldWindows[1])
        await store(.bottomRight, tokens: MenuBarCommand.Token.bottomRight(), for: oldWindows[2])
        for x in 0..<3 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = Array(oldWindows[1..<3])
      } else if oldWindows.count >= 4 {
        tokens = tiling.tokens
        await store(.topLeft, tokens: MenuBarCommand.Token.bottomLeft(), for: nextWindow)
        await store(.topRight, tokens: MenuBarCommand.Token.topLeft(), for: oldWindows[1])
        await store(.bottomLeft, tokens: MenuBarCommand.Token.topRight(), for: oldWindows[2])
        await store(.bottomRight, tokens: MenuBarCommand.Token.bottomRight(), for: oldWindows[3])
        for x in 0..<4 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = Array(oldWindows.prefix(4))
      } else {
        return
      }
    case .previousSize:
      tokens = MenuBarCommand.Token.returnPreviousSize()
      await store(nil, for: nextWindow)
      updateSubjects = []
    }

    await MainActor.run {
      currentTask?.cancel()
      currentTask = Task { @MainActor in
        try Task.checkCancellation()

        let activeTokens: [MenuBarCommand.Token]
        let currentStorage = storage[nextWindow.windowNumber]

        switch tiling {
        case .fill:
          if let currentStorage, currentStorage.isFullScreen {
            activeTokens = currentStorage.tokens
            if currentStorage.isFullScreen {
              updateStore(isFullScreen: false, isCentered: false, for: nextWindow)
            }
          } else {
            activeTokens = tokens
            updateStore(isFullScreen: true, isCentered: false, for: nextWindow)
          }
        case .center:
          if let currentStorage, currentStorage.isCentered {
            activeTokens = currentStorage.tokens
            if currentStorage.isCentered {
              updateStore(isFullScreen: false, isCentered: false, for: nextWindow)
            }
          } else {
            activeTokens = tokens
            updateStore(isFullScreen: false, isCentered: true, for: nextWindow)
          }
        default:
          activeTokens = tokens
          updateStore(isFullScreen: false, isCentered: false, for: nextWindow)
        }

        let match = try recursiveSearch(activeTokens, items: menuItems)
        try Task.checkCancellation()
        match.performAction(.pick)

        if !updateSubjects.isEmpty {
          try await Task.sleep(for: .milliseconds(100))

          let newSnapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
          let windowNumbers = updateSubjects.map { $0.windowNumber }
          let newWindows = newSnapshot.windows.visibleWindowsInStage
            .filter { $0.rect.intersects(visibleScreenFrame) && windowNumbers.contains($0.windowNumber) }

          determineTiling(for: updateSubjects, in: visibleScreenFrame, newWindows: newWindows)
        }
      }
    }
  }

  @MainActor
  private static func store(_ tiling: WindowTiling?, tokens: [MenuBarCommand.Token] = [], for window: WindowModel) {
    guard tiling != nil else {
      storage[window.windowNumber] = nil
      return
    }
    storage[window.windowNumber] = TileStorage(tokens: tokens,
                                               isFullScreen: storage[window.windowNumber]?.isFullScreen ?? false,
                                               isCentered: storage[window.windowNumber]?.isCentered ?? false)
  }

  @MainActor
  private static func updateStore(isFullScreen: Bool, isCentered: Bool, for window: WindowModel) {
    guard let old = storage[window.windowNumber] else { return }
    storage[window.windowNumber] = TileStorage(tokens: old.tokens, isFullScreen: isFullScreen, isCentered: isCentered)
  }

  @MainActor
  private static func determineTiling(for subjects: [WindowModel],
                                      in screenFrame: CGRect,
                                      newWindows: [WindowModel]) {
    guard subjects.isEmpty == false else { return }

    let halfWidth = screenFrame.width / 2
    let halfHeight = screenFrame.height / 2

    func determineQuarter(for rect: CGRect) -> WindowTiling {
      let centerX = rect.midX
      let centerY = rect.midY

      if centerX < halfWidth && centerY < halfHeight {
        return .topLeft
      } else if centerX >= halfWidth && centerY < halfHeight {
        return .topRight
      } else if centerX < halfWidth && centerY >= halfHeight {
        return .bottomLeft
      } else {
        return .bottomRight
      }
    }

    for (oldWindow, newWindow) in zip(subjects, newWindows) {
      let oldQuarter = determineQuarter(for: oldWindow.rect)
      let newQuarter = determineQuarter(for: newWindow.rect)

      if oldQuarter != newQuarter {
        store(newQuarter, tokens: newQuarter.tokens, for: oldWindow)
        if Self.debug { print("Window \(oldWindow.ownerName) moved from \(oldQuarter) to \(newQuarter)") }
      } else {
        store(oldQuarter, tokens: newQuarter.tokens, for: oldWindow)
        if Self.debug { print("Window \(oldWindow.ownerName) stayed in \(oldQuarter)") }
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

private extension MenuBarCommand.Token {
  static func top() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top")]
  }

  static func left() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left")]
  }

  static func right() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Right")]
  }

  static func bottom() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom")]
  }

  static func topLeft() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top Left")]
  }

  static func topRight() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top Right")]
  }

  static func bottomLeft() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom Left")]
  }

  static func bottomRight() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom Right")]
  }

  static func center() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Center")]
  }

  static func fill() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Fill")]
  }

  static func zoom() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Fill")]
  }

  static func topBottom() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top & Bottom")]
  }

  static func bottomTop() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top & Bottom")]
  }

  static func leftRight() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left & Right")]
  }

  static func rightLeft() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Right & Left")]
  }


  static func leftQuarters() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left & Quarters")]
  }

  static func rightQuarters() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Right & Quarters")]
  }

  static func topQuarters() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top & Quarters")]
  }

  static func bottomQuarters() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom & Quarters")]
  }

  static func quarters() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Quarters")]
  }

  static func returnPreviousSize() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Return to Previous Size")]
  }
}

extension UserDefaults: @unchecked @retroactive Sendable { }

fileprivate struct TileStorage {
  let tokens: [MenuBarCommand.Token]
  let isFullScreen: Bool
  let isCentered: Bool
}

fileprivate extension WindowTiling {
  var tokens: [MenuBarCommand.Token] {
    switch self {
    case .left: MenuBarCommand.Token.left()
    case .right: MenuBarCommand.Token.right()
    case .top: MenuBarCommand.Token.top()
    case .bottom: MenuBarCommand.Token.bottom()
    case .topLeft: MenuBarCommand.Token.topLeft()
    case .topRight: MenuBarCommand.Token.topRight()
    case .bottomLeft: MenuBarCommand.Token.bottomLeft()
    case .bottomRight: MenuBarCommand.Token.bottomRight()
    case .center: []
    case .fill: []
    case .zoom: []
    case .arrangeLeftRight: MenuBarCommand.Token.leftRight()
    case .arrangeRightLeft: MenuBarCommand.Token.rightLeft()
    case .arrangeTopBottom: MenuBarCommand.Token.topBottom()
    case .arrangeBottomTop: MenuBarCommand.Token.bottomTop()
    case .arrangeLeftQuarters: MenuBarCommand.Token.leftQuarters()
    case .arrangeRightQuarters: MenuBarCommand.Token.rightQuarters()
    case .arrangeTopQuarters: MenuBarCommand.Token.topQuarters()
    case .arrangeBottomQuarters: MenuBarCommand.Token.bottomQuarters()
    case .arrangeQuarters: MenuBarCommand.Token.quarters()
    case .previousSize: []
    }
  }
}

import AXEssibility
import Cocoa
import Foundation
import Windows

final class SystemWindowTilingRunner {
  nonisolated(unsafe) static var debug: Bool = false
  @MainActor private static var currentTask: Task<Void, any Error>?
  @MainActor private static var storage = [WindowModel.WindowNumber: TileStorage]()
  private static let tilingWindowSpacingKey: String = "TiledWindowSpacing"

  static func initialIndex() {
    Task {
      let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
      for screen in NSScreen.screens {
        let visibleScreenFrame = screen.visibleFrame.mainDisplayFlipped
        let newWindows = snapshot.windows.visibleWindowsInStage
          .filter({ visibleScreenFrame.contains($0.rect) })
        await determineTiling(for: newWindows, in: visibleScreenFrame, newWindows: newWindows)
      }
    }
  }

  static func run(_ tiling: WindowTiling, toggleFill: Bool = true, snapshot: UserSpace.Snapshot) async throws {
    guard let screen = NSScreen.main, let runningApplication = NSWorkspace.shared.frontmostApplication else {
      return
    }

    await FocusBorder.shared.dismiss()

    let visibleScreenFrame = screen.visibleFrame.mainDisplayFlipped

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

    let activatedTiling: WindowTiling
    let updateSubjects: [WindowModel]

    // Pre-cache window tiling for new windows.
    if await storage[nextWindow.windowNumber] == nil {
      let tiling = calculateTiling(for: nextWindow.rect, ownerName: nextWindow.ownerName, in: visibleScreenFrame)
      await store(tiling, for: nextWindow)
    }

    switch tiling {
    case .left:
      activatedTiling = tiling
      await store(tiling, for: nextWindow)
      updateSubjects = []
    case .right:
      activatedTiling = tiling
      await store(tiling, for: nextWindow)
      updateSubjects = []
    case .top:
      activatedTiling = tiling
      await store(tiling, for: nextWindow)
      updateSubjects = []
    case .bottom:
      activatedTiling = tiling
      await store(tiling, for: nextWindow)
      updateSubjects = []
    case .topLeft:
      activatedTiling = tiling
      await store(tiling, for: nextWindow)
      updateSubjects = []
    case .topRight:
      activatedTiling = tiling
      await store(tiling, for: nextWindow)
      updateSubjects = []
    case .bottomLeft:
      activatedTiling = tiling
      await store(tiling, for: nextWindow)
      updateSubjects = []
    case .bottomRight:
      activatedTiling = tiling
      await store(tiling, for: nextWindow)
      updateSubjects = []
    case .center:
      activatedTiling = tiling
      updateSubjects = [nextWindow]
    case .fill:
      activatedTiling = tiling
      updateSubjects = []
    case .zoom:
      activatedTiling = tiling
      updateSubjects = [nextWindow]
    case .previousSize:
      activatedTiling = tiling
      updateSubjects = [nextWindow]
    case .arrangeLeftRight:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = [nextWindow]
      } else {
        activatedTiling = WindowTiling.arrangeLeftRight
        updateSubjects = Array(oldWindows.prefix(2))
      }
    case .arrangeRightLeft:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = [nextWindow]
      } else {
        activatedTiling = WindowTiling.arrangeRightLeft
        updateSubjects = Array(oldWindows.prefix(2))
      }
    case .arrangeTopBottom:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = [nextWindow]
      } else {
        activatedTiling = WindowTiling.arrangeTopBottom
        updateSubjects = Array(oldWindows.prefix(2))
      }
    case .arrangeBottomTop:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = [nextWindow]
      } else {
        activatedTiling = WindowTiling.arrangeBottomTop
        updateSubjects = Array(oldWindows.prefix(2))
      }
    case .arrangeLeftQuarters:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = [nextWindow]
      } else if oldWindows.count == 2 {
        activatedTiling = WindowTiling.arrangeLeftRight
        updateSubjects = Array(oldWindows.prefix(2))
      } else {
        activatedTiling = tiling
        updateSubjects = Array(oldWindows.prefix(3))
      }
    case .arrangeDynamicQuarters:
      let tiling: WindowTiling = calculateTiling(for: nextWindow.rect, ownerName: nextWindow.ownerName, in: visibleScreenFrame)
      let leftTilings = [WindowTiling.left, .topLeft, .bottomLeft, .fill]

      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = [nextWindow]
      } else if oldWindows.count == 2 {
        if leftTilings.contains(tiling) {
          activatedTiling = WindowTiling.arrangeLeftRight
        } else {
          activatedTiling = WindowTiling.arrangeRightLeft
        }
        updateSubjects = Array(oldWindows.prefix(2))
      } else {
        if leftTilings.contains(tiling) {
          activatedTiling = .arrangeLeftQuarters
        } else {
          activatedTiling = .arrangeRightQuarters
        }

        updateSubjects = Array(oldWindows.prefix(3))
      }
    case .arrangeRightQuarters:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = [nextWindow]
      } else if oldWindows.count == 2 {
        activatedTiling = WindowTiling.arrangeRightLeft
        updateSubjects = Array(oldWindows.prefix(2))
      } else {
        activatedTiling = tiling
        updateSubjects = Array(oldWindows.prefix(3))
      }
    case .arrangeTopQuarters:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = [nextWindow]
      } else if oldWindows.count == 2 {
        activatedTiling = WindowTiling.arrangeTopBottom
        updateSubjects = Array(oldWindows.prefix(2))
      } else {
        activatedTiling = tiling
        updateSubjects = Array(oldWindows.prefix(3))
      }
    case .arrangeBottomQuarters:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = [nextWindow]
      } else if oldWindows.count == 2 {
        activatedTiling = WindowTiling.arrangeBottomTop
        updateSubjects = Array(oldWindows.prefix(2))
      } else {
        activatedTiling = tiling
        updateSubjects = Array(oldWindows.prefix(3))
      }
    case .arrangeQuarters:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = [nextWindow]
      } else if oldWindows.count == 2 {
        activatedTiling = WindowTiling.arrangeLeftRight
        updateSubjects = Array(oldWindows.prefix(2))
      } else if oldWindows.count == 3 {
        activatedTiling = WindowTiling.arrangeLeftQuarters
        updateSubjects = Array(oldWindows.prefix(3))
      } else {
        activatedTiling = tiling
        updateSubjects = Array(oldWindows.prefix(4))
      }
    }

    await MainActor.run {
      currentTask?.cancel()
      currentTask = Task { @MainActor in
        try Task.checkCancellation()

        let currentStorage = storage[nextWindow.windowNumber]
        var nextTiling: WindowTiling

        switch (activatedTiling, toggleFill) {
        case (.fill, true):
          if let currentStorage, currentStorage.isFullScreen {
            if currentStorage.tiling == activatedTiling {
              nextTiling = .center
              updateStore(isFullScreen: false, isCentered: false, in: visibleScreenFrame, for: nextWindow)
            } else if currentStorage.isFullScreen {
              nextTiling = currentStorage.tiling
              updateStore(isFullScreen: false, isCentered: false, in: visibleScreenFrame, for: nextWindow)
            } else {
              nextTiling = .fill
              updateStore(isFullScreen: false, isCentered: false, in: visibleScreenFrame, for: nextWindow)
            }
          } else {
            nextTiling = activatedTiling
            updateStore(isFullScreen: true, isCentered: false, in: visibleScreenFrame, for: nextWindow)
          }
        default:
          nextTiling = activatedTiling
          updateStore(isFullScreen: false, isCentered: false, in: visibleScreenFrame, for: nextWindow)
        }

        guard let match = WindowTilingMenuItemFinder.find(nextTiling, in: menuItems) else { return }

        try Task.checkCancellation()
        match.performAction(.pick)

        if !updateSubjects.isEmpty {
          try await Task.sleep(for: .milliseconds(325))

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
  private static func store(_ tiling: WindowTiling?, for window: WindowModel) {
    guard let tiling else {
      storage[window.windowNumber] = nil
      return
    }
    storage[window.windowNumber] = TileStorage(
      tiling: tiling,
      isFullScreen: storage[window.windowNumber]?.isFullScreen ?? false,
      isCentered: storage[window.windowNumber]?.isCentered ?? false)
  }

  @MainActor
  private static func updateStore(isFullScreen: Bool, isCentered: Bool, in screenFrame: CGRect, for window: WindowModel) {
    let currentTiling = calculateTiling(for: window.rect, ownerName: window.ownerName, in: screenFrame)
    storage[window.windowNumber] = TileStorage(tiling: currentTiling, isFullScreen: isFullScreen, isCentered: isCentered)
  }

  @MainActor
  private static func determineTiling(for subjects: [WindowModel],
                                      in screenFrame: CGRect,
                                      newWindows: [WindowModel]) {
    guard subjects.isEmpty == false else { return }

    for (oldWindow, newWindow) in zip(subjects, newWindows) {
      let oldTiling = calculateTiling(for: oldWindow.rect, ownerName: oldWindow.ownerName, in: screenFrame)
      let newTiling = calculateTiling(for: newWindow.rect, ownerName: newWindow.ownerName, in: screenFrame)

      if oldTiling != newTiling {
        store(newTiling, for: oldWindow)
        if Self.debug { print("Window \(oldWindow.ownerName) moved from \(oldTiling) to \(newTiling)") }
      } else {
        store(oldTiling, for: oldWindow)
        if Self.debug { print("Window \(oldWindow.ownerName) stayed in \(oldTiling)") }
      }
    }
  }

  static func calculateTiling(for rect: CGRect, ownerName: String? = nil, in screenFrame: CGRect) -> WindowTiling {
    let windowSpacing: CGFloat
    if UserDefaults(suiteName: "com.apple.WindowManager")?.bool(forKey: "EnableTiledWindowMargins") == false {
      windowSpacing = 0
    } else {
      windowSpacing = max(CGFloat(UserDefaults(suiteName: "com.apple.WindowManager")?.float(forKey: "TiledWindowSpacing") ?? 8), 0)
    }

    let screenInsetFrame = screenFrame.insetBy(dx: windowSpacing, dy: windowSpacing)
    let delta = screenInsetFrame.delta(rect)

    let halfWidth = Int(screenInsetFrame.width / 2 + screenFrame.origin.x)
    let halfHeight = Int(screenInsetFrame.height / 2 + screenFrame.origin.y)
    let centerX = Int(rect.midX)
    let centerY = Int(rect.midY)
    let width = Int(rect.width)
    let height = Int(rect.height)
    let widthDelta = abs(Int(screenInsetFrame.width) - width)
    let heightDelta = abs(Int(screenInsetFrame.height) - height)

    let isTopLeft = centerX < halfWidth && centerY < halfHeight + Int(windowSpacing)
    let isTopRight = centerX >= halfWidth && centerY < halfHeight + Int(windowSpacing)
    let isBottomLeft = centerX < halfWidth && centerY > halfHeight + Int(windowSpacing)
    let isBottomRight = centerX >= halfWidth && centerY > halfHeight + Int(windowSpacing)
    let isFill = delta.size.inThreshold(min(windowSpacing, 1))
    let isCenter = Int(rect.midX) == Int(screenFrame.midX)

    var xOffset: CGFloat = windowSpacing
    for screen in NSScreen.screens {
      if screen.visibleFrame.mainDisplayFlipped == screenFrame {
        break
      }
      xOffset = screen.frame.maxX
    }

    let leftThreshold = Int(rect.origin.x - xOffset)
    let isLeft = rect.minY == screenFrame.minY + windowSpacing && leftThreshold <= halfWidth && height >= halfHeight
    let isRight = max(rect.maxX, rect.maxX + 1) >= screenFrame.maxX - windowSpacing && height >= halfHeight + Int(windowSpacing)
    let isTop = rect.minY == screenFrame.minY + windowSpacing && width >= halfWidth + Int(windowSpacing)
    let isBottom = rect.maxY == screenFrame.maxY - windowSpacing && width >= halfWidth + Int(windowSpacing)

    if isFill || widthDelta == 0 && heightDelta == 0 {
      return .fill
    } else if isTopLeft {
      return .topLeft
    } else if isTopRight {
      return .topRight
    } else if isBottomRight {
      return .bottomRight
    } else if isBottomLeft {
      return .bottomLeft
    } else if isRight {
      return .right
    } else if isLeft {
      return .left
    } else if isTop {
      return .top
    } else if isBottom {
      return .bottom
    } else if isCenter {
      return .center
    } else {
      return .fill
    }
  }
}

extension UserDefaults: @unchecked @retroactive Sendable { }

fileprivate struct TileStorage {
  let tiling: WindowTiling
  let isFullScreen: Bool
  let isCentered: Bool
}

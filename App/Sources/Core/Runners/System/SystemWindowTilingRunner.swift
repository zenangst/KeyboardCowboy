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

    switch tiling {
    case .left:
      activatedTiling = tiling
      updateSubjects = [nextWindow]
    case .right:
      activatedTiling = tiling
      updateSubjects = [nextWindow]
    case .top:
      activatedTiling = tiling
      updateSubjects = [nextWindow]
    case .bottom:
      activatedTiling = tiling
      updateSubjects = [nextWindow]
    case .topLeft:
      activatedTiling = tiling
      updateSubjects = [nextWindow]
    case .topRight:
      activatedTiling = tiling
      updateSubjects = [nextWindow]
    case .bottomLeft:
      activatedTiling = tiling
      updateSubjects = [nextWindow]
    case .bottomRight:
      activatedTiling = tiling
      updateSubjects = [nextWindow]
    case .center:
      activatedTiling = tiling
      updateSubjects = []
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
        if let previousTiling = await storage[nextWindow.windowNumber],
           previousTiling.isFullScreen, previousTiling.tiling == .right {
          activatedTiling = .arrangeRightQuarters
        } else if leftTilings.contains(tiling) {
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
            nextTiling = currentStorage.tiling
            if currentStorage.isFullScreen {
              updateStore(isFullScreen: false, isCentered: false, for: nextWindow)
            }
          } else {
            nextTiling = activatedTiling
            updateStore(isFullScreen: true, isCentered: false, for: nextWindow)
          }
        default:
          nextTiling = activatedTiling
          updateStore(isFullScreen: false, isCentered: false, for: nextWindow)
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
  private static func updateStore(isFullScreen: Bool, isCentered: Bool, for window: WindowModel) {
    guard let old = storage[window.windowNumber] else { return }
    storage[window.windowNumber] = TileStorage(tiling: old.tiling, isFullScreen: isFullScreen, isCentered: isCentered)
  }

  @MainActor
  private static func determineTiling(for subjects: [WindowModel],
                                      in screenFrame: CGRect,
                                      newWindows: [WindowModel]) {
    guard subjects.isEmpty == false else { return }

    for (oldWindow, newWindow) in zip(subjects, newWindows) {
      let oldTiling = calculateTiling(for: oldWindow.rect, in: screenFrame)
      let newTiling = calculateTiling(for: newWindow.rect, in: screenFrame)

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
    let windowSpacing = min(CGFloat(UserDefaults(suiteName: "com.apple.WindowManager")?.float(forKey: "TiledWindowSpacing") ?? 8), 20)
    let screenFrame = screenFrame.insetBy(dx: windowSpacing, dy: windowSpacing)
    let halfWidth = screenFrame.width / 2
    let halfHeight = screenFrame.height / 2
    let centerX = rect.midX
    let centerY = rect.midY
    let width = rect.width
    let height = rect.height
    let widthTreshold: CGFloat = abs(width - halfWidth)
    let heightTreshold: CGFloat = abs(height - halfHeight)

    let widthDelta = screenFrame.width - width
    let heightDelta = screenFrame.height - height

    if widthDelta == 0 && heightDelta == 0 {
      return .fill
    }

    // Check for half-screen positions
    if widthTreshold <= halfWidth && height >= halfHeight {
      if rect.minX == screenFrame.minX {
        return .left
      } else if rect.maxX == screenFrame.maxX {
        return .right
      }
    } else if heightTreshold <= halfHeight && width >= screenFrame.width - windowSpacing * 2 {
      if rect.minY == screenFrame.minY {
        return .top
      } else if rect.maxY == screenFrame.maxY {
        return .bottom
      }
    }

    // Located in the center
    let delta = abs(centerX - screenFrame.midX)
    if delta <= max(windowSpacing,1) {
      return .left
    }

    // Determine quarter
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
}

extension UserDefaults: @unchecked @retroactive Sendable { }

fileprivate struct TileStorage {
  let tiling: WindowTiling
  let isFullScreen: Bool
  let isCentered: Bool
}

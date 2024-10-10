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
      await store(.left, for: nextWindow)
      updateSubjects = []
    case .right:
      activatedTiling = tiling
      await store(.right, for: nextWindow)
      updateSubjects = []
    case .top:
      activatedTiling = tiling
      await store(.top, for: nextWindow)
      updateSubjects = []
    case .bottom:
      activatedTiling = tiling
      await store(.bottom, for: nextWindow)
      updateSubjects = []
    case .topLeft:
      activatedTiling = tiling
      await store(.topLeft, for: nextWindow)
      updateSubjects = []
    case .topRight:
      activatedTiling = tiling
      await store(.topRight, for: nextWindow)
      updateSubjects = []
    case .bottomLeft:
      activatedTiling = tiling
      await store(.bottomLeft, for: nextWindow)
      updateSubjects = []
    case .bottomRight:
      activatedTiling = tiling
      await store(.bottomRight, for: nextWindow)
      updateSubjects = []
    case .center:
      activatedTiling = tiling
      await store(.center, for: nextWindow)
      updateSubjects = []
    case .fill:
      activatedTiling = tiling
      updateSubjects = []
    case .zoom:
      activatedTiling = tiling
      await store(nil, for: nextWindow)
      updateSubjects = []
    case .previousSize:
      activatedTiling = tiling
      await store(nil, for: nextWindow)
      updateSubjects = []
    case .arrangeLeftRight:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
      } else {
        activatedTiling = WindowTiling.arrangeLeftRight
        await store(.left, for: oldWindows[0])
        await store(.right, for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      }
      updateSubjects = []
    case .arrangeRightLeft:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
      } else {
        activatedTiling = WindowTiling.arrangeRightLeft
        await store(.right, for: oldWindows[0])
        await store(.left, for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      }
      updateSubjects = []
    case .arrangeTopBottom:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
      } else {
        activatedTiling = WindowTiling.arrangeTopBottom
        await store(.top, for: oldWindows[0])
        await store(.bottom, for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      }
      updateSubjects = []
    case .arrangeBottomTop:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
      } else {
        activatedTiling = WindowTiling.arrangeBottomTop
        await store(.bottom, for: oldWindows[0])
        await store(.top, for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      }
      updateSubjects = []
    case .arrangeLeftQuarters:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = []
      } else if oldWindows.count == 2 {
        activatedTiling = WindowTiling.arrangeLeftRight
        await store(.left, for: oldWindows[0])
        await store(.right, for: oldWindows[1])
        updateSubjects = []
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      } else {
        activatedTiling = tiling
        await store(.left, for: oldWindows[0])
        await store(.bottomRight, for: oldWindows[1])
        await store(.topRight, for: oldWindows[2])
        updateSubjects = Array(oldWindows[1...2])
        for x in 0..<3 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      }
    case .arrangeDynamicQuarters:
      let tiling: WindowTiling = calculateTiling(for: nextWindow.rect, in: visibleScreenFrame)
      let leftTilings = [WindowTiling.left, .topLeft, .bottomLeft]

      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = []
      } else if oldWindows.count == 2 {
        if leftTilings.contains(tiling) {
          activatedTiling = WindowTiling.arrangeLeftRight
          await store(.left, for: oldWindows[0])
          await store(.right, for: oldWindows[1])
        } else {
          activatedTiling = WindowTiling.arrangeRightLeft
          await store(.right, for: oldWindows[0])
          await store(.left, for: oldWindows[1])
        }
        updateSubjects = []
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      } else {
        if leftTilings.contains(tiling) {
          await store(.left, for: oldWindows[0])
          activatedTiling = .arrangeLeftQuarters
        } else {
          await store(.right, for: oldWindows[0])
          activatedTiling = .arrangeRightQuarters
        }

        await store(.bottomRight, for: oldWindows[1])
        await store(.topRight, for: oldWindows[2])
        updateSubjects = Array(oldWindows[1...2])
        for x in 0..<3 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
      }
    case .arrangeRightQuarters:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = []
      } else if oldWindows.count == 2 {
        activatedTiling = WindowTiling.arrangeRightLeft
        await store(.top, for: oldWindows[0])
        await store(.left, for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = []
      } else {
        activatedTiling = tiling
        await store(.right, for: oldWindows[0])
        await store(.topLeft, for: oldWindows[2])
        await store(.bottomLeft, for: oldWindows[1])
        for x in 0..<3 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = Array(oldWindows[1..<3])
      }
    case .arrangeTopQuarters:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = []
      } else if oldWindows.count == 2 {
        activatedTiling = WindowTiling.arrangeTopBottom
        await store(.top, for: oldWindows[0])
        await store(.bottom, for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = []
      } else {
        activatedTiling = tiling
        await store(.top, for: oldWindows[0])
        await store(.bottomRight, for: oldWindows[1])
        await store(.bottomLeft, for: oldWindows[2])
        for x in 0..<3 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = Array(oldWindows[1..<3])
      }
    case .arrangeBottomQuarters:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = []
      } else if oldWindows.count == 2 {
        activatedTiling = WindowTiling.arrangeBottomTop
        await store(.bottom, for: oldWindows[0])
        await store(.top, for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = []
      } else {
        activatedTiling = tiling
        await store(.bottom, for: oldWindows[0])
        await store(.topLeft, for: oldWindows[2])
        await store(.topRight, for: oldWindows[1])
        for x in 0..<3 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = Array(oldWindows[1..<3])
      }
    case .arrangeQuarters:
      if oldWindows.count == 1 {
        activatedTiling = WindowTiling.fill
        updateSubjects = []
      } else if oldWindows.count == 2 {
        activatedTiling = WindowTiling.arrangeLeftRight
        await store(.left, for: nextWindow)
        await store(.right, for: oldWindows[1])
        for x in 0..<2 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = []
      } else if oldWindows.count == 3 {
        activatedTiling = WindowTiling.arrangeLeftQuarters
        await store(.left, for: nextWindow)
        await store(.topRight, for: oldWindows[1])
        await store(.bottomRight, for: oldWindows[2])
        for x in 0..<3 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
        updateSubjects = Array(oldWindows[1..<3])
      } else {
        activatedTiling = tiling
        await store(.topLeft, for: nextWindow)
        await store(.topRight, for: oldWindows[1])
        await store(.bottomLeft, for: oldWindows[2])
        await store(.bottomRight, for: oldWindows[3])
        for x in 0..<4 { await updateStore(isFullScreen: false, isCentered: false, for: oldWindows[x]) }
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

  private static func calculateTiling(for rect: CGRect, in screenFrame: CGRect) -> WindowTiling {
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

    // Check for half-screen positions
    if widthTreshold < windowSpacing && height >= halfHeight {
      if rect.minX == screenFrame.minX {
        return .left
      } else if rect.maxX == screenFrame.maxX {
        return .right
      }
    } else if heightTreshold < windowSpacing && width >= screenFrame.width - windowSpacing * 2 {
      if rect.minY == screenFrame.minY {
        return .top
      } else if rect.maxY == screenFrame.maxY {
        return .bottom
      }
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

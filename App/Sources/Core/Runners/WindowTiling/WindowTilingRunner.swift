import AXEssibility
import Bonzai
import Cocoa
import Foundation
import SwiftUI
import Windows

enum WindowTilingRunner {
  nonisolated(unsafe) static var debug: Bool = false
  @MainActor private static var currentTask: Task<Void, any Error>?
  @MainActor private static var saveTask: Task<Void, any Error>?
  @MainActor private static var storage = [WindowModel.WindowNumber: TileStorage]()

  static func index() {
    Task {
      let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
      for screen in NSScreen.screens {
        let visibleScreenFrame = screen.visibleFrame.mainDisplayFlipped
        let newWindows = snapshot.windows
          .visibleWindowsInStage
          .filter { visibleScreenFrame.contains($0.rect) }
        await determineTiling(for: newWindows, in: visibleScreenFrame, newWindows: newWindows)
      }
    }
  }

  static func run(_ tiling: WindowTiling, toggleFill: Bool = true, snapshot: UserSpace.Snapshot) async throws {
    guard let screen = NSScreen.main else {
      return
    }

    await FocusBorder.shared.dismiss()

    let visibleScreenFrame = screen.visibleFrame.mainDisplayFlipped

    await currentTask?.cancel()
    await saveTask?.cancel()

    let oldSnapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
    let oldWindows = oldSnapshot.windows
      .visibleWindowsInStage
      .filter { $0.rect.intersects(visibleScreenFrame) }

    guard let nextWindow = oldWindows.first else { return }

    let app = AppAccessibilityElement(snapshot.frontMostApplication.ref.processIdentifier)
    let menuItems = try app
      .menuBar()
      .menuItems()

    let activatedTiling: WindowTiling
    let updateSubjects: [WindowModel]

    // Pre-cache window tiling for new windows.
    let currentTiling: WindowTiling?
    if await storage[nextWindow.windowNumber] == nil {
      currentTiling = await calculateTiling(for: nextWindow.rect, ownerName: nextWindow.ownerName, in: visibleScreenFrame)
      await store(currentTiling, for: nextWindow)
    } else {
      currentTiling = await getTiling(for: nextWindow)
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
      let tiling: WindowTiling = await calculateTiling(for: nextWindow.rect,
                                                       ownerName: nextWindow.ownerName,
                                                       in: visibleScreenFrame)
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
            } else if currentStorage.isFullScreen && currentStorage.tiling != .fill {
              // this is where we are at.
              nextTiling = currentStorage.tiling
            } else {
              nextTiling = .fill
            }
            let isFullScreen = nextTiling == .fill
            let isCentered = nextTiling == .center
            updateStore(currentTiling, isFullScreen: isFullScreen, isCentered: isCentered, in: visibleScreenFrame, for: nextWindow)
          } else {
            nextTiling = activatedTiling
            let isFullScreen = nextTiling == .fill
            let isCentered = nextTiling == .center
            updateStore(currentTiling, isFullScreen: isFullScreen, isCentered: isCentered, in: visibleScreenFrame, for: nextWindow)
          }
        default:
          nextTiling = activatedTiling
          let isFullScreen = nextTiling == .fill
          let isCentered = nextTiling == .center
          let storedTiling: WindowTiling

          if isFullScreen == false && isCentered == false {
            storedTiling = currentStorage?.tiling ?? nextTiling
          } else if isFullScreen == false && isCentered == true {
            storedTiling = nextTiling
          } else {
            storedTiling = nextTiling
          }

          updateStore(storedTiling, isFullScreen: false, isCentered: false, in: visibleScreenFrame, for: nextWindow)
        }

        guard let match = WindowTilingMenuItemFinder.find(nextTiling, in: menuItems) else { return }

        if Self.debug {
          print("activating", nextTiling)
        }

        try Task.checkCancellation()
        match.performAction(.pick)

        let originalPoint = NSEvent.mouseLocation.mainDisplayFlipped
        let matchingScreen = NSScreen.screens.first { screen in
          screen.frame.contains(originalPoint)
        }

        if matchingScreen != NSScreen.main {
          if let axWindow = try? app.windows().first(where: { $0.id == nextWindow.id }),
             let windowFrame = axWindow.frame
          {
            let midPoint = CGPoint(x: windowFrame.midX,
                                   y: windowFrame.midY)
            NSCursor.moveCursor(to: midPoint)
          }
        }

        if !updateSubjects.isEmpty {
          try await Task.sleep(for: .milliseconds(325))

          let newSnapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
          let windowNumbers = updateSubjects.map { $0.windowNumber }
          let newWindows = newSnapshot.windows
            .visibleWindowsInStage
            .filter { $0.rect.intersects(visibleScreenFrame) && windowNumbers.contains($0.windowNumber) }

          determineTiling(for: updateSubjects, in: visibleScreenFrame, newWindows: newWindows)
        }
      }
    }
  }

  @MainActor private static func getTiling(for window: WindowModel) -> WindowTiling? {
    storage[window.windowNumber]?.tiling
  }

  @MainActor private static func store(_ tiling: WindowTiling?, for window: WindowModel) {
    guard let tiling else {
      storage[window.windowNumber] = nil
      return
    }

    let isFullScreen: Bool = if let storageIsFullScreen = storage[window.windowNumber]?.isFullScreen {
      storageIsFullScreen
    } else {
      tiling == .fill ? true : false
    }

    let isCentered: Bool = if let storageIsCenter = storage[window.windowNumber]?.isCentered {
      storageIsCenter
    } else {
      tiling == .center ? true : false
    }

    storage[window.windowNumber] = TileStorage(
      tiling: tiling,
      isFullScreen: isFullScreen,
      isCentered: isCentered
    )
  }

  @MainActor
  private static func updateStore(_ tiling: WindowTiling?, isFullScreen: Bool, isCentered: Bool, in screenFrame: CGRect, for window: WindowModel) {
    let currentTiling = tiling ?? calculateTiling(for: window.rect, ownerName: window.ownerName, in: screenFrame)
    storage[window.windowNumber] = TileStorage(tiling: currentTiling, isFullScreen: isFullScreen, isCentered: isCentered)
  }

  @MainActor
  private static func determineTiling(for subjects: [WindowModel],
                                      in screenFrame: CGRect,
                                      newWindows: [WindowModel])
  {
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

  @MainActor
  static func calculateTiling(for rect: CGRect, ownerName _: String? = nil, in screenFrame: CGRect) -> WindowTiling {
    let windowSpacing: CGFloat = UserSettings.WindowManager.tiledWindowSpacing
    let currentScreen = NSScreen.main!
    let offset = currentScreen.frame.maxY - currentScreen.visibleFrame.maxY
    let screenInsetFrame = screenFrame.insetBy(dx: windowSpacing, dy: windowSpacing)
    let delta = screenInsetFrame.delta(rect)
    let halfWidth = Int(screenFrame.width / 2 + screenFrame.origin.x - (windowSpacing * 2))
    let halfHeight = Int(screenFrame.height / 2 + screenFrame.origin.y - (windowSpacing * 2) - offset)
    let width = Int(rect.width)
    let height = Int(rect.height)
    let widthDelta = abs(Int(screenInsetFrame.width) - width)
    let heightDelta = abs(Int(screenInsetFrame.height) - height)

    let containerSize = CGSize(width: halfWidth,
                               height: halfHeight)

    let topLeftRect = CGRect(origin: .init(x: windowSpacing, y: windowSpacing + offset),
                             size: containerSize)
    let bottomLeftRect = CGRect(origin: CGPoint(x: windowSpacing, y: windowSpacing * 3 + containerSize.height + offset),
                                size: containerSize)
    let topRightRect = CGRect(origin: CGPoint(x: containerSize.width + windowSpacing * 3, y: windowSpacing + offset),
                              size: containerSize)
    let bottomRightRect = CGRect(origin: CGPoint(x: containerSize.width + windowSpacing * 3, y: windowSpacing * 3 + containerSize.height + offset),
                                 size: containerSize)
    let isTopLeft = rect.intersects(topLeftRect)
    let isTopRight = rect.intersects(topRightRect)
    let isBottomLeft = rect.intersects(bottomLeftRect)
    let isBottomRight = rect.intersects(bottomRightRect)
    let isFill = delta.size.inThreshold(min(windowSpacing, 1))
    let isCenter = Int(rect.midX) == Int(screenFrame.midX)

    let isLeft = isTopLeft && isBottomLeft
    let isRight = isTopRight && isBottomRight
    let isTop = isTopLeft && isTopRight
    let isBottom = isBottomLeft && isBottomRight
    let isFillZeroDelta = isFill || widthDelta == 0 && heightDelta == 0

    let result: WindowTiling = if isFillZeroDelta {
      .fill
    } else if isCenter { .center }
    else if isLeft { .left }
    else if isRight { .right }
    else if isTop { .top }
    else if isBottom { .bottom }
    else if isTopLeft { .topLeft }
    else if isTopRight { .topRight }
    else if isBottomRight { .bottomRight }
    else if isBottomLeft { .bottomLeft }
    else { .fill }

    if Self.debug {
      print("isTopLeft", isTopLeft)
      print("isBottomLeft", isBottomLeft)
      print("isTopRight", isTopRight)
      print("isBottomRight", isBottomRight)
      print("isFill", isFill)
      print("isCenter", isCenter)
      print("result", result)
      print("--------")
    }

    return result
  }
}

extension UserDefaults: @unchecked @retroactive Sendable { }

private struct TileStorage {
  let tiling: WindowTiling
  let isFullScreen: Bool
  let isCentered: Bool
}

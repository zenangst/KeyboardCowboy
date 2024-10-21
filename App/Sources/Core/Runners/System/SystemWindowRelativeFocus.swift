import AppKit
import Apps
import AXEssibility
import Foundation
import Windows

final class SystemWindowRelativeFocus {
  private static let debug: Bool = false

  nonisolated(unsafe) static var mouseFollow: Bool = true

  enum Direction {
    case up, down, left, right
  }

  let navigation = SystemWindowRelativeFocusNavigation()
  @MainActor
  var consumedWindows = Set<RelativeWindowModel>()
  var previousDirection: Direction?

  init() {}

  @MainActor
  func reset() {
    consumedWindows.removeAll()
  }

  @MainActor
  func run(_ direction: Direction, snapshot: UserSpace.Snapshot) async throws {
    FocusBorder.shared.dismiss()

    if direction != previousDirection {
      previousDirection = direction
      consumedWindows.removeAll()
    }

    let windows = indexWindowsInStage(getWindows())
    let frontMostApplication = snapshot.frontMostApplication
    let frontMostAppElement = AppAccessibilityElement(frontMostApplication.ref.processIdentifier)
    var activeWindow: RelativeWindowModel?

    let focusedWindow = try? frontMostAppElement.focusedWindow()
    for window in windows {
      guard let focusedWindow else {
        activeWindow = window
        break
      }

      if window.id == focusedWindow.id {
        activeWindow = window
        break
      }
    }

    if activeWindow == nil, !windows.isEmpty {
      activeWindow = windows.first
    }

    var matchedWindow: RelativeWindowModel?
    if let activeWindow {
      matchedWindow = try await navigation.findNextWindow(activeWindow, windows: windows, direction: direction) ?? activeWindow
    }

    guard let nextWindow = matchedWindow else { return }

    consumedWindows.insert(nextWindow)

    let processIdentifier = pid_t(nextWindow.ownerPid)
    let appElement = AppAccessibilityElement(processIdentifier)
    let match = try appElement.windows().first(where: { $0.id == nextWindow.id })

    if let match,
       let frame = match.frame,
       let previousWindow = activeWindow,
       nextWindow.id != previousWindow.id {
      FocusBorder.shared.show(nextWindow.rect.mainDisplayFlipped)
      NSRunningApplication(processIdentifier: processIdentifier)?.activate()
      match.performAction(.raise)

      let originalPoint = NSEvent.mouseLocation.mainDisplayFlipped
      let targetPoint = CGPoint(x: frame.midX, y: frame.midY)
      let previousScreen = NSScreen.screens.first(where: { $0.visibleFrame.contains(previousWindow.rect) }) ?? NSScreen.screens[0]
      let nextScreen = NSScreen.screens.first(where: { $0.visibleFrame.contains(targetPoint) }) ?? NSScreen.screens[0]
      let previousTiling = SystemWindowTilingRunner.calculateTiling(for: previousWindow.rect, ownerName: previousWindow.ownerName, in: previousScreen.visibleFrame.mainDisplayFlipped)
      let nextTiling = SystemWindowTilingRunner.calculateTiling(for: nextWindow.rect, ownerName: nextWindow.ownerName, in: nextScreen.visibleFrame.mainDisplayFlipped)

      if nextTiling == .fill {
        if previousScreen != nextScreen  {
          let midPoint = CGPoint(x: frame.midX,
                                 y: frame.midY)
          NSCursor.moveCursor(to: midPoint)
          return
        }
      }

      let clickPoint: CGPoint

      if Self.debug {
        print("🔀", direction, "from", previousWindow.ownerName, "(\(previousTiling)) to", nextWindow.ownerName, "(\(nextTiling))")
      }

      switch(direction, previousTiling, nextTiling) {
      case (.down, .topLeft, .left),
           (.down, .left, .bottomLeft),
           (.down, .bottomLeft, .left),
           (.down, .topLeft, .bottomLeft):
        clickPoint = CGPoint(x: frame.minX, y: frame.maxY)
      case (.down, .topRight, .right),
           (.down, .topLeft, .bottomRight),
           (.down, .right, .bottomRight),
           (.down, .right, .right),
           (.down, .bottomRight, .right),
           (.down, .topRight, .bottomRight),
           (.down, .left, .bottomRight),
           (.right, .left, .bottom),
           (.right, .left, .right),
           (.right, .bottomLeft, .right):
        clickPoint = CGPoint(x: frame.maxX, y: frame.maxY)
      case (.left, .right, .topRight),
           (.down, .right, .bottom):
        clickPoint = CGPoint(x: frame.minX, y: frame.maxY)
      case (.down, .left, .bottom),
           (.left, .bottomRight, .left),
           (.down, .left, .left):
        clickPoint = CGPoint(x: frame.minX, y: frame.minX)
      case (.right, .bottomLeft, .center):
        clickPoint = CGPoint(x: frame.midX + 1.5, y: frame.midY + 1.5)
      case (.left, .right, .center), (.left, .bottomRight, .center):
        clickPoint = CGPoint(x: frame.midX - 1.5, y: frame.midY - 1.5)
      default:
        clickPoint = CGPoint(x: frame.midX, y: frame.minY)
      }

      if Self.debug {
        print("🐭", clickPoint)
      }

      // Verify that the window that we are trying to mouse click
      // is actually the match that we got from `navigation.findNextWindow`
      let systemElement = SystemAccessibilityElement()
      let windowId = systemElement.element(at: clickPoint, as: AnyAccessibilityElement.self)?.window?.id
      guard match.id == windowId else {
        NSCursor.moveCursor(to: targetPoint)
        return
      }

      let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: clickPoint, mouseButton: .left)
      let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: clickPoint, mouseButton: .left)

      mouseDown?.post(tap: .cghidEventTap)
      mouseUp?.post(tap: .cghidEventTap)

      for _ in 0..<4 {
        NSCursor.moveCursor(to: Self.mouseFollow ? targetPoint : originalPoint)
      }
    }
  }

  // MARK: Private methods

  private func getWindows() -> [WindowModel] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  private func indexWindowsInStage(_ models: [WindowModel]) -> [RelativeWindowModel] {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 300, height: 200)
    let windows: [WindowModel] = models
      .filter {
        $0.id > 0 &&
        $0.ownerName != "borders" &&
        $0.isOnScreen &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        $0.alpha == 1 &&
        !excluded.contains($0.ownerName)
      }

    return windows.map(RelativeWindowModel.init)
  }
}

struct RelativeWindowModel: Hashable, Identifiable {
  public let id: Int
  public let ownerPid: Int
  public let ownerName: String
  public var rect: CGRect

  init(_ windowModel: WindowModel) {
    self.id = windowModel.id
    self.ownerPid = windowModel.ownerPid.rawValue
    self.ownerName = windowModel.ownerName
    self.rect = windowModel.rect
  }
}

struct RelativeSystemWindowModel {
  public let index: Int
  public let window: RelativeWindowModel
}


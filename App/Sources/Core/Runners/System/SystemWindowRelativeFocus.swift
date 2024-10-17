import AppKit
import Apps
import AXEssibility
import Foundation
import Windows

final class SystemWindowRelativeFocus {
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
      matchedWindow = await navigation.findNextWindow(activeWindow, windows: windows, direction: direction) ?? activeWindow
    }

    guard let matchedWindow else { return }

    consumedWindows.insert(matchedWindow)

    let processIdentifier = pid_t(matchedWindow.ownerPid)
    let appElement = AppAccessibilityElement(processIdentifier)
    let match = try appElement.windows().first(where: { $0.id == matchedWindow.id })

    if let match, let frame = match.frame {
      FocusBorder.shared.show(matchedWindow.rect.mainDisplayFlipped)
      NSRunningApplication(processIdentifier: processIdentifier)?.activate()
      match.performAction(.raise)

      let originalPoint = NSEvent.mouseLocation.mainDisplayFlipped
      let targetPoint = CGPoint(x: frame.midX, y: frame.midY)
      let screen = NSScreen.screens.first(where: { $0.visibleFrame.contains(targetPoint) }) ?? NSScreen.screens[0]
      let tiling = SystemWindowTilingRunner.calculateTiling(for: matchedWindow.rect, in: screen.visibleFrame.mainDisplayFlipped)
      let clickPoint: CGPoint

      switch (direction, tiling) {
      case (.left, .left), (.left, .topLeft), (.up, .topLeft), (.left, .fill):
        clickPoint = CGPoint(x: frame.minX, y: frame.minY)
      case (.right, .right), (.right, .topRight), (.up, .topRight), (.right, .fill):
        clickPoint = CGPoint(x: frame.maxX, y: frame.minY)
      case (.down, .bottomLeft):
        clickPoint = CGPoint(x: frame.minX, y: frame.maxY)
      case (.down, .bottomRight):
        clickPoint = CGPoint(x: frame.maxX, y: frame.maxY)
      default:
        clickPoint = CGPoint(x: frame.midX, y: frame.minY)
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


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
  var consumedWindows = Set<WindowModel>()
  var previousDirection: Direction?

  init() {}

  func reset() {
    consumedWindows.removeAll()
  }

  func run(_ direction: Direction, snapshot: UserSpace.Snapshot) async throws {
    guard let screen = NSScreen.main else { return }

    await FocusBorder.shared.dismiss()

    if direction != previousDirection {
      previousDirection = direction
      consumedWindows.removeAll()
    }

    var windows = indexWindowsInStage(getWindows())

    let frontMostApplication = snapshot.frontMostApplication
    let frontMostAppElement = AppAccessibilityElement(frontMostApplication.ref.processIdentifier)
    var activeWindow: WindowModel?

    let focusedWindow = try? frontMostAppElement.focusedWindow()
    for (offset, window) in windows.enumerated() {
      guard let focusedWindow else {
        activeWindow = window
        windows.remove(at: offset)
        break
      }

      if window.id == focusedWindow.id {
        activeWindow = window
        consumedWindows.insert(window)
        windows.remove(at: offset)
        break
      }
    }

    if activeWindow == nil, !windows.isEmpty {
      activeWindow = windows.first
      windows.removeFirst()
    }

    windows.removeAll(where: { consumedWindows.contains($0) })

    guard let activeWindow,
          let matchedWindow = await navigation.findNextWindow(activeWindow, windows: windows, direction: direction) else {
      return
    }

    consumedWindows.insert(matchedWindow)

    let processIdentifier = pid_t(matchedWindow.ownerPid.rawValue)
    guard let runningApplication = NSRunningApplication(processIdentifier: processIdentifier) else { return }

    let appElement = AppAccessibilityElement(processIdentifier)
    let match = try appElement.windows().first(where: { $0.id == matchedWindow.id })

    let activationResult = runningApplication.activate()
    if !activationResult, let bundleURL = runningApplication.bundleURL {
      NSWorkspace.shared.open(bundleURL)
    }

    match?.performAction(.raise)

    var invertedFrame = matchedWindow.rect.invertedYCoordinate(on: screen)
    invertedFrame.origin.y += abs(screen.frame.height - screen.visibleFrame.height)
    await FocusBorder.shared.show(invertedFrame)

    if Self.mouseFollow, let match, let frame = match.frame {
      let targetPoint = CGPoint(x: frame.midX, y: frame.midY)
      NSCursor.moveCursor(to: targetPoint)
    }
  }

  // MARK: Private methods

  private func getWindows() -> [WindowModel] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  private func indexWindowsInStage(_ models: [WindowModel]) -> [WindowModel] {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 150, height: 150)
    let windows: [WindowModel] = models
      .filter {
        $0.id > 0 &&
        $0.ownerName != "borders" &&
        $0.ownerName != "Keyboard Cowboy" &&
        $0.isOnScreen &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        $0.alpha == 1 &&
        !excluded.contains($0.ownerName)
      }

    return windows
  }
}

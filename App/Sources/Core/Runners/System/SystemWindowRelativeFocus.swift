import AppKit
import Apps
import AXEssibility
import Foundation
import Windows

enum SystemWindowRelativeFocus {
  enum Direction {
    case up, down, left, right
  }

  static func run(_ direction: Direction, snapshot: UserSpace.Snapshot) throws {
    var windows = indexWindowsInStage(getWindows())
    let frontMostApplication = snapshot.frontMostApplication
    let frontMostAppElement = AppAccessibilityElement(frontMostApplication.ref.processIdentifier)
    var activeWindow: WindowModel?

    let focusedWindow = try? frontMostAppElement.focusedWindow()
    for (offset, window) in windows.enumerated() {
      // If the activate application doesn't have any focused window,
      // we should activate the first window in the list.
      // Examples of this include document based applications, such as Xcode & Safari.
      guard let focusedWindow else {
        activeWindow = window
        windows.remove(at: offset)
        break
      }

      if window.id == focusedWindow.id {
        activeWindow = window
        windows.remove(at: offset)
        break
      }
    }

    // If the active window couldn't be matched, we should activate the first window in the list.
    if activeWindow == nil {
      activeWindow = windows.first
      windows.removeFirst()
    }

    guard let activeWindow = activeWindow else { return }

    var matchedWindow: WindowModel?
    switch direction {
    case .up:
      matchedWindow = findAbove(activeWindow, windows: windows)
    case .down:
      matchedWindow = findBelow(activeWindow, windows: windows)
    case .left:
      matchedWindow = findLeft(activeWindow, windows: windows)
    case .right:
      matchedWindow = findRight(activeWindow, windows: windows)
    }

    guard let matchedWindow else { return }

    let processIdentifier = pid_t(matchedWindow.ownerPid.rawValue)
    guard let runningApplication = NSRunningApplication(processIdentifier: processIdentifier) else { return }
    let appElement = AppAccessibilityElement(processIdentifier)
    let match = try appElement.windows().first(where: { $0.id == matchedWindow.id })

    let activationResult = runningApplication.activate()
    if !activationResult, let bundleURL = runningApplication.bundleURL {
      NSWorkspace.shared.open(bundleURL)
    }

    match?.performAction(.raise)
  }

  // MARK: - Private methods

  private static func getWindows() -> [WindowModel] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  private static func indexWindowsInStage(_ models: [WindowModel]) -> [WindowModel] {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 300, height: 300)
    let windows: [WindowModel] = models
      .filter {
        $0.id > 0 &&
        $0.isOnScreen &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        $0.alpha == 1 &&
        !excluded.contains($0.ownerName)
      }

    return windows
  }

  private static func findLeft(_ activeWindow: WindowModel, windows: [WindowModel]) -> WindowModel? {
    var matchedWindow: WindowModel?
    let midX = activeWindow.rect.midX
    let midY = activeWindow.rect.midY
    var cursor = CGPoint(x: midX, y: midY)

    // Iterate through the windows array to find the first window that contains midX
    while cursor.x > 0 {
      for window in windows {
        if window.rect.contains(cursor) && window.rect.minX < activeWindow.rect.minX {
          matchedWindow = window
          break
        }
      }
      if matchedWindow != nil {
        break
      }
      cursor.x -= 1
    }


    if matchedWindow == nil {
      // Fallback to the right side of the screen if no windows are found to the left.
      matchedWindow = windows
        .filter({ $0.rect.origin.x < activeWindow.rect.origin.x })
        .sorted(by: { $0.rect.origin.x > $1.rect.origin.x })
        .first
    }

    // Wrap around to the right side of the screen if no windows are found to the left.
    if matchedWindow == nil {
      matchedWindow = windows
        .sorted(by: { $0.rect.origin.x < $1.rect.origin.x })
        .last
    }

    return matchedWindow
  }

  private static func findRight(_ activeWindow: WindowModel, windows: [WindowModel]) -> WindowModel? {
    var matchedWindow: WindowModel?
    let midX = activeWindow.rect.midX
    let midY = activeWindow.rect.midY
    var cursor = CGPoint(x: midX, y: midY)
    let screenWidth = NSScreen.main?.frame.width ?? CGFloat.greatestFiniteMagnitude

    // Iterate through the windows array to find the first window that contains midX
    while cursor.x < screenWidth {
      for window in windows {
        if window.rect.contains(cursor) && window.rect.minX > activeWindow.rect.minX {
          matchedWindow = window
          break
        }
      }
      if matchedWindow != nil {
        break
      }
      cursor.x += 1
    }

    // Fallback to the right side of the screen if no windows are found to the left.
    if matchedWindow == nil {
      matchedWindow = windows
        .filter({ $0.rect.origin.x > activeWindow.rect.origin.x })
        .sorted(by: { $0.rect.origin.x < $1.rect.origin.x })
        .first
    }

    // Wrap around to the left side of the screen if no windows are found to the right.
    if matchedWindow == nil {
      matchedWindow = windows
        .sorted(by: { $0.rect.origin.x < $1.rect.origin.x })
        .first
    }

    return matchedWindow
  }

  private static func findAbove(_ activeWindow: WindowModel, windows: [WindowModel]) -> WindowModel? {
    var matchedWindow: WindowModel?
    let midX = activeWindow.rect.midX
    let midY = activeWindow.rect.midY
    var cursor = CGPoint(x: midX, y: midY)

    // Iterate through the windows array to find the first window that contains midY
    while cursor.y > 0 {
      for window in windows {
        if window.rect.contains(cursor) && window.rect.maxY < activeWindow.rect.maxY {
          matchedWindow = window
          break
        }
      }
      if matchedWindow != nil {
        break
      }
      cursor.y -= 1
    }

    // Fallback to the bottom of the screen if no windows are found above.
    if matchedWindow == nil {
      matchedWindow = windows
        .filter({ $0.rect.maxY <= activeWindow.rect.maxY })
        .sorted(by: { $0.rect.maxY > $1.rect.maxY })
        .first
    }

    // Wrap around to the top of the screen if no windows are found above.
    if matchedWindow == nil {
      matchedWindow = windows
        .sorted(by: { $0.rect.maxY < $1.rect.maxY })
        .last
    }

    return matchedWindow
  }

  private static func findBelow(_ activeWindow: WindowModel, windows: [WindowModel]) -> WindowModel? {
    var matchedWindow: WindowModel?
    let midX = activeWindow.rect.midX
    let midY = activeWindow.rect.midY
    var cursor = CGPoint(x: midX, y: midY)
    let screenHeight = NSScreen.main?.frame.height ?? CGFloat.greatestFiniteMagnitude

    while cursor.y < screenHeight {
      for window in windows {
        if window.rect.contains(cursor) && window.rect.minY > activeWindow.rect.minY {
          matchedWindow = window
          break
        }
      }
      if matchedWindow != nil {
        break
      }
      cursor.y += 1
    }

    // Fallback to the bottom of the screen if no windows are found below.
    if matchedWindow == nil {
      matchedWindow = windows
        .filter({ $0.rect.maxY >= activeWindow.rect.maxY })
        .sorted(by: { $0.rect.maxY < $1.rect.maxY })
        .first
    }

    // Wrap around to the top of the screen if no windows are found below.
    if matchedWindow == nil {
      matchedWindow = windows
        .sorted(by: { $0.rect.maxY < $1.rect.maxY })
        .first
    }

    return matchedWindow
  }

}

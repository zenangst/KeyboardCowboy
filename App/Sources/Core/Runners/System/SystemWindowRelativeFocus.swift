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
      matchedWindow = windows
        .filter({ $0.rect.maxY <= activeWindow.rect.maxY })
        .sorted(by: { $0.rect.maxY > $1.rect.maxY })
        .first
      if matchedWindow == nil {
        matchedWindow = windows
          .sorted(by: { $0.rect.maxY < $1.rect.maxY })
          .last
      }
    case .down:
      matchedWindow = windows
        .filter({ $0.rect.maxY >= activeWindow.rect.maxY })
        .sorted(by: { $0.rect.maxY < $1.rect.maxY })
        .first
      if matchedWindow == nil {
        matchedWindow = windows
          .sorted(by: { $0.rect.maxY < $1.rect.maxY })
          .first
      }
    case .left:
      matchedWindow = windows
        .filter({ $0.rect.origin.x < activeWindow.rect.origin.x })
        .sorted(by: { $0.rect.origin.x > $1.rect.origin.x })
        .first

      if matchedWindow == nil {
        matchedWindow = windows
          .sorted(by: { $0.rect.maxX < $1.rect.maxX })
          .last
      }
    case .right:
      matchedWindow = windows
        .filter({ $0.rect.origin.x > activeWindow.rect.origin.x })
        .sorted(by: { $0.rect.origin.x < $1.rect.origin.x })
        .first
      if matchedWindow == nil {
        matchedWindow = windows
          .sorted(by: { $0.rect.origin.x < $1.rect.origin.x })
          .first
      }
    }

    guard let matchedWindow else {
      return
    }

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
        !excluded.contains($0.ownerName)
      }

    return windows
  }
}

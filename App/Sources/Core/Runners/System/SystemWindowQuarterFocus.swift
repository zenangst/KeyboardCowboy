import AppKit
import Apps
import AXEssibility
import Foundation
import Windows

final class SystemWindowQuarterFocus {
  enum Quarter {
    case upperLeft
    case upperRight
    case lowerLeft
    case lowerRight
  }

  var consumedWindows = Set<WindowModel>()
  var previousQuarter: Quarter?

  init() {}

  func reset() {
    consumedWindows.removeAll()
  }

  func run(_ quarter: Quarter, snapshot: UserSpace.Snapshot) throws {
    guard let userDefaults = UserDefaults(suiteName: "com.apple.WindowManager") else {
      return
    }

    let windowSpacing: CGFloat = CGFloat(userDefaults.float(forKey: "TiledWindowSpacing"))

    guard let screen = NSScreen.main else {
      return
    }

    if quarter != previousQuarter {
      previousQuarter = quarter
      consumedWindows.removeAll()
    }

    var windows = indexWindowsInStage(getWindows())
    let frontMostApplication = snapshot.frontMostApplication
    let frontMostAppElement = AppAccessibilityElement(frontMostApplication.ref.processIdentifier)
    var activeWindow: WindowModel?

    let focusedWindow = try? frontMostAppElement.focusedWindow()
    var activeWindowOffset: Int? = nil
    for (offset, window) in windows.enumerated() {
      guard let focusedWindow else {
        activeWindow = window
        activeWindowOffset = offset
        break
      }

      if window.id == focusedWindow.id {
        activeWindow = window
        activeWindowOffset = offset
        break
      }
    }

    windows.removeAll(where: { consumedWindows.contains($0) })

    let targetRect: CGRect = quarter.targetRect(on: screen, spacing: windowSpacing)

    if let activeWindow, targetRect.intersects(activeWindow.rect), let activeWindowOffset {
      consumedWindows.insert(activeWindow)
      windows.remove(at: activeWindowOffset)
    }

    guard let matchedWindow = windows.first(where: { targetRect.intersects($0.rect) }) else {
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

    consumedWindows.removeAll()
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
        $0.isOnScreen &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        $0.alpha == 1 &&
        !excluded.contains($0.ownerName)
      }

    return windows
  }
}

extension SystemWindowQuarterFocus.Quarter {
  func targetRect(on screen: NSScreen, spacing: CGFloat) -> CGRect {
    let screenFrame = screen.frame
    let halfWidth = (screenFrame.width / 2) - spacing
    let halfHeight = (screenFrame.height / 2) - spacing
    let spacing: CGFloat = spacing

    switch self {
    case .upperLeft:
      return CGRect(x: screenFrame.minX + spacing, y: screenFrame.minY + spacing, width: halfWidth, height: halfHeight)
    case .upperRight:
      return CGRect(x: screenFrame.midX + spacing, y: screenFrame.minY + spacing, width: halfWidth, height: halfHeight)
    case .lowerLeft:
      return CGRect(x: screenFrame.minX + spacing, y: screenFrame.midY + spacing, width: halfWidth, height: halfHeight)
    case .lowerRight:
      return CGRect(x: screenFrame.midX + spacing, y: screenFrame.midY + spacing, width: halfWidth, height: halfHeight)
    }
  }
}

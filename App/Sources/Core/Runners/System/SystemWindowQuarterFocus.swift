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
  var initialWindows = [WindowModel]()

  init() {
    initialWindows = indexWindowsInStage(getWindows())
  }

  func reset() {
    consumedWindows.removeAll()
    initialWindows = indexWindowsInStage(getWindows())
  }

  func run(_ quarter: Quarter, snapshot: UserSpace.Snapshot) throws {
    guard let userDefaults = UserDefaults(suiteName: "com.apple.WindowManager") else {
      return
    }

    let windowSpacing: CGFloat = CGFloat(userDefaults.float(forKey: "TiledWindowSpacing"))

    guard let screen = NSScreen.main else { return }

    if quarter != previousQuarter {
      previousQuarter = quarter
      reset()
    }

    var windows = initialWindows
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

    windows.removeAll(where: { consumedWindows.contains($0) })

    let targetRect: CGRect = quarter.targetRect(on: screen, spacing: windowSpacing)
      .insetBy(dx: 200, dy: 100)

    let quarterFilter: (WindowModel) -> Bool = {
      targetRect.intersects($0.rect)
    }
    var validQuarterWindows = windows.filter(quarterFilter)
    if validQuarterWindows.isEmpty {
      validQuarterWindows = initialWindows.filter { quarterFilter($0) && $0 != activeWindow }
      consumedWindows.removeAll()
    }

    guard let matchedWindow = validQuarterWindows.first(where: {
      targetRect.intersects($0.rect.insetBy(dx: windowSpacing * 2, dy: windowSpacing * 2))
    }) else {
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
    let screenFrame = screen.visibleFrame
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

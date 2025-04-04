import AXEssibility
import Cocoa
import Windows

final class WindowFocusAccordian {
  enum Direction {
    case up, down, left, right
  }

  @MainActor
  static func run(_ direction: Direction, nextActiveWindow: WindowAccessibilityElement? = nil) {
    guard let screen = NSScreen.main else { return }

    let windows = indexWindowsInStage(getWindows(), targetRect: screen.visibleFrame)
    let windowIds = windows.map(\.id)
    let pids = windows.map(\.ownerPid.rawValue)
    let runningApplications = NSWorkspace.shared.runningApplications.filter { pids.contains(Int($0.processIdentifier)) }

    var axWindows = [WindowAccessibilityElement]()
    var activeWindow: WindowAccessibilityElement? = nextActiveWindow

    for runningApplication in runningApplications {
      let axApp = AppAccessibilityElement(runningApplication.processIdentifier)

      if var resolvedWindows = try? axApp.windows()
        .filter({ windowIds.contains(Int($0.id)) }) {

        if let nextActiveWindow {
          resolvedWindows.removeAll(where: { $0.id == nextActiveWindow.id })
        } else if runningApplication.isActive {
          activeWindow = resolvedWindows.first
          resolvedWindows.remove(at: 0)
        }

        axWindows.append(contentsOf: resolvedWindows)
      }
    }

    guard let activeWindow, let activeWindowFrame = activeWindow.frame else { return }

    let windowSort: (_ lhs: WindowAccessibilityElement, _ rhs: WindowAccessibilityElement) -> Bool = {
      guard let lhs = $0.frame, let rhs = $1.frame else { return false }
      return lhs.origin.x < rhs.origin.x
    }

    let sortedWindows = axWindows.sorted(by: windowSort)
    let midIndex = sortedWindows.count / 2

    var leftWindows = Array(sortedWindows[..<midIndex])
    var rightWindows = Array(sortedWindows[midIndex...])

    let didLayout = layout(
      activeWindow,
      currentWindowFrame: activeWindowFrame,
      leftWindows: leftWindows,
      rightWindows: rightWindows,
      on: screen
    )

    if !didLayout {
      leftWindows.sort(by: windowSort)
      rightWindows.sort(by: windowSort)

      switch direction {
      case .down: break
      case .up: break
      case .left:
        guard let pid = leftWindows.first?.app?.pid,
              let runningApplication = NSWorkspace.shared.runningApplications.first(where: {
                $0.processIdentifier == pid
              }) else { return }

        guard let nextWindow = leftWindows.first(where: {
          guard let frame = $0.frame else { return false }
          return frame.origin.x < (activeWindow.frame?.origin.x ?? 0)
        }) else { return }

        guard let nextFrame = nextWindow.frame else { return }

        if leftWindows.isEmpty {
          leftWindows.append(activeWindow)
        } else {
          rightWindows.append(activeWindow)
        }

        nextWindow.main = true
        nextWindow.performAction(.raise)

        if #available(macOS 14.0, *) {
          runningApplication.activate(from: NSWorkspace.shared.frontmostApplication!,
                                      options: .activateIgnoringOtherApps)
        } else {
          runningApplication.activate(options: .activateIgnoringOtherApps)
        }

        _ = layout(
          nextWindow,
          currentWindowFrame: nextFrame,
          leftWindows: leftWindows,
          rightWindows: rightWindows,
          on: screen
        )
      case .right:
        guard let pid = rightWindows.first?.app?.pid,
              let runningApplication = NSWorkspace.shared.runningApplications.first(where: {
                $0.processIdentifier == pid
              }) else { return }

        guard let nextWindow = leftWindows.first(where: {
          guard let frame = $0.frame else { return false }
          return frame.origin.x < (activeWindow.frame?.origin.x ?? 0)
        }) else { return }

        guard let nextFrame = nextWindow.frame else { return }

        if rightWindows.isEmpty {
          rightWindows.append(activeWindow)
        } else {
          leftWindows.append(activeWindow)
        }

        nextWindow.main = true
        nextWindow.performAction(.raise)

        if #available(macOS 14.0, *) {
          runningApplication.activate(from: NSWorkspace.shared.frontmostApplication!,
                                      options: .activateIgnoringOtherApps)
        } else {
          runningApplication.activate(options: .activateIgnoringOtherApps)
        }

        _ = layout(
          nextWindow,
          currentWindowFrame: nextFrame,
          leftWindows: leftWindows,
          rightWindows: rightWindows,
          on: screen
        )
      }
    }
  }

  @MainActor
  private static func layout(_ activeWindow: WindowAccessibilityElement,
                             currentWindowFrame: CGRect,
                             leftWindows: [WindowAccessibilityElement],
                             rightWindows: [WindowAccessibilityElement],
                             on screen: NSScreen) -> Bool {
    var didLayout = false

    let screenFrame = screen.visibleFrame
    let padding: CGFloat = 8
    let screenFrameY =  screenFrame.origin.y + (screen.frame.height - screenFrame.height) + padding
    let windowWidth: CGFloat = (screenFrame.width - 2 * padding) * 0.8
    let windowHeight: CGFloat = screenFrame.height - 2 * padding

    let activeWindowX = screenFrame.origin.x + (screenFrame.width - windowWidth) / 2
    let activeWindowFrame = CGRect(x: activeWindowX,
                                   y: screenFrameY,
                                   width: windowWidth,
                                   height: windowHeight)

    if activeWindowFrame.hasDifference(greaterThan: 2, comparedTo: currentWindowFrame) {
      activeWindow.frame = activeWindowFrame
      didLayout = true
    }

    let leftPadding = (screen.frame.origin.x + activeWindowX) / CGFloat(leftWindows.count)
    let rightPadding = (screen.frame.origin.x + activeWindowX) / CGFloat(rightWindows.count)

    for (offset, window) in leftWindows.enumerated() {
      let nextX = leftPadding * CGFloat(offset)

      let nextFrame = CGRect(x: nextX, y: screenFrameY,
                             width: windowWidth, height: windowHeight)

      guard let currentFrame = window.frame else { continue }

      if nextFrame.hasDifference(greaterThan: 2, comparedTo: currentFrame) {
        window.frame = nextFrame
        window.performAction(.raise)
        didLayout = true
      }
    }

    for (offset, window) in rightWindows.reversed().enumerated() {
      guard let currentFrame = window.frame else { continue }

      let nextX = screenFrame.width - currentFrame.width - rightPadding * CGFloat(offset)
      let nextFrame = CGRect(x: nextX, y: screenFrameY,
                             width: windowWidth, height: windowHeight)

      if nextFrame.hasDifference(greaterThan: 2, comparedTo: currentFrame) {
        window.frame = nextFrame
        window.performAction(.raise)
        didLayout = true
      }
    }

    return didLayout
  }

  private static func getWindows() -> [WindowModel] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  private static func indexWindowsInStage(_ models: [WindowModel], targetRect: CGRect) -> [WindowModel] {
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
        !excluded.contains($0.ownerName) &&
        $0.rect.intersects(targetRect)
      }

    return windows
  }
}

extension CGRect {
  static func compare(lhs: CGRect, rhs: CGRect) -> Bool {
    Int(lhs.origin.x) == Int(rhs.origin.x) &&
    Int(lhs.origin.y) == Int(rhs.origin.y) &&
    Int(lhs.size.width) == Int(rhs.size.width) &&
    Int(lhs.size.height) == Int(rhs.size.height)
  }
}

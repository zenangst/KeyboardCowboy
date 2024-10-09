import AppKit
import Apps
import AXEssibility
import Bonzai
import CoreGraphics
import Foundation
import SwiftUI
import Windows

final class SystemWindowQuarterFocus: @unchecked Sendable {
  enum Quarter {
    case upperLeft
    case upperRight
    case lowerLeft
    case lowerRight
  }

  nonisolated(unsafe) static var debug: Bool = false
  nonisolated(unsafe) static var mouseFollow: Bool = true

  private var consumedWindows = Set<WindowModel>()
  private var previousQuarter: Quarter?
  private var initialWindows = [WindowModel]()
  @MainActor lazy var debugWindow: NSWindow = ZenWindow(
    animationBehavior: .none,
    content: RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 4))
  @MainActor lazy var debugWindowController: NSWindowController = NSWindowController(window: debugWindow)

  init() {
    initialWindows = indexWindowsInStage(getWindows())
  }

  func reset() {
    consumedWindows.removeAll()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
      guard let self else { return }
      initialWindows = indexWindowsInStage(getWindows())
    }
    previousQuarter = nil
  }

  @MainActor
  func run(_ quarter: Quarter, snapshot: UserSpace.Snapshot) throws {
    guard let userDefaults = UserDefaults(suiteName: "com.apple.WindowManager") else {
      return
    }

    let windowSpacing: CGFloat = CGFloat(userDefaults.float(forKey: "TiledWindowSpacing"))

    guard let screen = NSScreen.main else { return }

    FocusBorder.shared.dismiss()

    if quarter != previousQuarter {
      reset()
      previousQuarter = quarter
    }

    var activeWindow: WindowModel?
    var windows = initialWindows

    let frontMostApplication = snapshot.frontMostApplication
    let frontMostAppElement = AppAccessibilityElement(frontMostApplication.ref.processIdentifier)

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

    let targetRect: CGRect = quarter.targetRect(on: screen, widthFactor: 0.1, heightFactor: 0.175, spacing: windowSpacing)

    if Self.debug {
      let invertedRect = targetRect.invertedYCoordinate(on: screen)
      debugWindowController.window?.setFrame(invertedRect, display: true)
      debugWindowController.showWindow(nil)
    }

    let quarterFilter: (WindowModel) -> Bool = {
      targetRect.intersects($0.rect)
    }
    var validQuarterWindows = windows.filter(quarterFilter)
    if validQuarterWindows.isEmpty {
      validQuarterWindows = initialWindows.filter { quarterFilter($0) && $0 != activeWindow }
      consumedWindows.removeAll()
    }

    guard let matchedWindow = validQuarterWindows.first(where: quarterFilter) else {
      return
    }

    var invertedFrame = matchedWindow.rect.invertedYCoordinate(on: screen)
    invertedFrame.origin.y += abs(screen.frame.height - screen.visibleFrame.height)
    FocusBorder.shared.show(invertedFrame)

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
    let minimumSize = CGSize(width: 300, height: 200)
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

extension SystemWindowQuarterFocus.Quarter {
  func targetRect(on screen: NSScreen, widthFactor: CGFloat, heightFactor: CGFloat, spacing: CGFloat) -> CGRect {
    let screenFrame = CGRect(
      x: screen.frame.origin.x,
      y: 0,
      width: screen.visibleFrame.width,
      height: screen.visibleFrame.height
    )
    let targetWidth = screenFrame.width * widthFactor
    let targetHeight = screenFrame.height * heightFactor

    switch self {
    case .upperLeft:
      return CGRect(x: screenFrame.minX + spacing,
                    y: screenFrame.minY + spacing,
                    width: targetWidth,
                    height: targetHeight)
    case .upperRight:
      return CGRect(x: screenFrame.maxX - targetWidth - spacing,
                    y: screenFrame.minY + spacing,
                    width: targetWidth,
                    height: targetHeight)
    case .lowerLeft:
      return CGRect(x: screenFrame.minX + spacing,
                    y: screenFrame.maxY - targetHeight - spacing,
                    width: targetWidth,
                    height: targetHeight)
    case .lowerRight:
      return CGRect(x: screenFrame.maxX - targetWidth - spacing,
                    y: screenFrame.maxY - targetHeight - spacing,
                    width: targetWidth,
                    height: targetHeight)
    }
  }
}

extension CGRect {
  func invertedYCoordinate(on screen: NSScreen) -> CGRect {
    let screenFrame = screen.visibleFrame
    let invertedY = screenFrame.maxY - self.origin.y - self.height

    return CGRect(x: self.origin.x, y: invertedY, width: self.width, height: self.height)
  }
}

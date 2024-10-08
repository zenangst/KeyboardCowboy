import AXEssibility
import Bonzai
import Cocoa
import Windows
import SwiftUI

final class SystemWindowCenterFocus: @unchecked Sendable {
  nonisolated(unsafe) static var debug: Bool = false
  nonisolated(unsafe) static var mouseFollow: Bool = true

  private var consumedWindows = Set<WindowModel>()
  private var initialWindows = [WindowModel]()

  @MainActor lazy var window: NSWindow = ZenWindow(
    animationBehavior: .none,
    content: RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 4))
  @MainActor lazy var windowController: NSWindowController = NSWindowController(window: window)

  init() {
    guard let screen = NSScreen.main else { return }
    let targetRect = targetRect(on: screen)
    initialWindows = indexWindowsInStage(getWindows(), targetRect: targetRect)
  }

  func reset() {
    consumedWindows.removeAll()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
      guard let self, let screen = NSScreen.main else { return }
      let targetRect = targetRect(on: screen)
      initialWindows = indexWindowsInStage(getWindows(), targetRect: targetRect)
    }
  }

  @MainActor
  func run(snapshot: UserSpace.Snapshot) async throws {
    guard let screen = NSScreen.main else { return }

    guard let userDefaults = UserDefaults(suiteName: "com.apple.WindowManager") else {
      return
    }

    let windowSpacing: CGFloat = CGFloat(userDefaults.float(forKey: "TiledWindowSpacing"))
    // These are used to figure out if the window is using window tiling or not
    let minX = screen.visibleFrame.minX + windowSpacing
    let maxX = screen.visibleFrame.maxX - (windowSpacing * 2)

    var activeWindow: WindowModel?
    var windows = initialWindows

    let targetRect = targetRect(on: screen)
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

    if Self.debug {
      let invertedRect = targetRect.invertedYCoordinate(on: screen)
      windowController.window?.setFrame(invertedRect, display: true)
      windowController.showWindow(nil)
    }

    // Check that the windows rect interects the target rectangle and verify that
    // the matched window is not using tiling.
    let quarterFilter: (WindowModel) -> Bool = {
      targetRect.intersects($0.rect) && ($0.rect.minX > minX && $0.rect.maxX < maxX)
    }
    var validQuarterWindows = windows.filter(quarterFilter)
    if validQuarterWindows.isEmpty {
      validQuarterWindows = initialWindows.filter { quarterFilter($0) && $0 != activeWindow }
      consumedWindows.removeAll()
    }

    FocusBorder.shared.dismiss()
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

  private func targetRect(on screen: NSScreen) -> CGRect {
    let size: CGFloat = 2
    let origin = CGPoint(x: screen.frame.midX - size, y: screen.frame.midY - size)
    let targetRect: CGRect = CGRect(origin: origin, size: CGSize(width: size, height: size))
    return targetRect
  }

  private func getWindows() -> [WindowModel] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  private func indexWindowsInStage(_ models: [WindowModel], targetRect: CGRect) -> [WindowModel] {
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
        !excluded.contains($0.ownerName) &&
        $0.rect.intersects(targetRect)
      }

    return windows
  }
}

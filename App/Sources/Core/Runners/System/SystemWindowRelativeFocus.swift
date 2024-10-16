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

    var windows = indexWindowsInStage(getWindows())

    let frontMostApplication = snapshot.frontMostApplication
    let frontMostAppElement = AppAccessibilityElement(frontMostApplication.ref.processIdentifier)
    var activeWindow: RelativeWindowModel?

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

    var matchedWindow: RelativeWindowModel?
    if let activeWindow {
      matchedWindow = await navigation.findNextWindow(activeWindow, windows: windows, direction: direction) ?? activeWindow
    }

    guard let matchedWindow else { return }

    consumedWindows.insert(matchedWindow)

    let processIdentifier = pid_t(matchedWindow.ownerPid)
    guard let runningApplication = NSRunningApplication(processIdentifier: processIdentifier) else { return }

    let appElement = AppAccessibilityElement(processIdentifier)
    let match = try appElement.windows().first(where: { $0.id == matchedWindow.id })

    let activationResult = runningApplication.activate()
    if !activationResult, let bundleURL = runningApplication.bundleURL {
      NSWorkspace.shared.open(bundleURL)
    }

    if let match, let frame = match.frame {
      FocusBorder.shared.show(matchedWindow.rect.mainDisplayFlipped)
      match.performAction(.raise)
      if Self.mouseFollow {
        let targetPoint = CGPoint(x: frame.midX, y: frame.midY)
        NSCursor.moveCursor(to: targetPoint)
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


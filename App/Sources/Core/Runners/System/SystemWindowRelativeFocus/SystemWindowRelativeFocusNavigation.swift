import AppKit
import Bonzai
import Foundation
import SwiftUI
import Windows

final class SystemWindowRelativeFocusNavigation: @unchecked Sendable {
  @MainActor lazy var window: NSWindow = ZenWindow(
    animationBehavior: .none,
    content: RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 4))
  @MainActor lazy var windowController: NSWindowController = NSWindowController(window: window)

  nonisolated(unsafe) static var debug: Bool = false

  fileprivate func rerouteDirectionIfNeeded(_ direction: inout SystemWindowRelativeFocus.Direction, frame: CGRect,
                                            tiling: WindowTiling?, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) {
    if direction == .left && frame.origin.x < 0 {
      if tiling == .topRight || tiling == .right {
        direction = .down
      } else if tiling == .bottomRight {
        direction = .up
      }
    } else if direction == .right && frame.maxX > maxX {
      if tiling == .topLeft || tiling == .left {
        direction = .down
      } else if tiling == .bottomLeft {
        direction = .up
      }
    } else if direction == .up && frame.minY < minY {
      if tiling == .bottom || tiling == .bottomRight {
        direction = .left
      } else if tiling == .bottomLeft {
        direction = .right
      }
    } else if direction == .down && frame.maxY > maxY {
      if tiling == .topLeft || tiling == .left {
        direction = .right
      } else {
        direction = .left
      }
    }
  }
  
  func findNextWindow(_ currentWindow: WindowModel, windows: [WindowModel], direction: SystemWindowRelativeFocus.Direction) async -> WindowModel? {
    let windowSpacing = max(min(CGFloat(UserDefaults(suiteName: "com.apple.WindowManager")?.float(forKey: "TiledWindowSpacing") ?? 8), 20), 1)
    var systemWindows = windows.systemWindows
      .sorted { $0.index < $1.index }

    if systemWindows.isEmpty { return nil }

    systemWindows.insert(SystemWindowModel(window: currentWindow, index: -1), at: 0)

    var occupiedRects = [CGRect]()
    var visibleWindows = [SystemWindowModel]()

    for systemWindow in systemWindows {
      let intersection = systemWindow.window.rect.intersection(currentWindow.rect)
      let percentage = CGSize(width: 1 - intersection.width / systemWindow.window.rect.width,
                              height: 1 - intersection.height / systemWindow.window.rect.height)

      guard percentage != .zero else { continue }

      if occupiedRects.first(where: {
        abs($0.origin.x - systemWindow.window.rect.origin.x) <= windowSpacing &&
        abs($0.origin.y - systemWindow.window.rect.origin.y) <= windowSpacing
      }) == nil {
        occupiedRects.append(systemWindow.window.rect)
        visibleWindows.append(systemWindow)
      }
    }

    let width = switch direction {
    case .up:    currentWindow.rect.size.width / 2
    case .down:  currentWindow.rect.size.width / 2
    case .left:  currentWindow.rect.size.width / 4
    case .right: currentWindow.rect.size.width / 4
    }

    let height = switch direction {
    case .up:    currentWindow.rect.size.height / 4
    case .down:  currentWindow.rect.size.height / 4
    case .left:  currentWindow.rect.size.height / 4
    case .right: currentWindow.rect.size.height / 4
    }

    let y = switch direction {
    case .up:    currentWindow.rect.minY
    case .down:  currentWindow.rect.maxY
    case .left:  currentWindow.rect.minY
    case .right: currentWindow.rect.minY
    }

    let x = switch direction {
    case .up:    currentWindow.rect.minX + width / 2
    case .down:  currentWindow.rect.midX - width / 2
    case .left:  currentWindow.rect.minX - width
    case .right: currentWindow.rect.maxX + width
    }

    var direction = direction
    var fieldOfView = CGRect(
      origin: CGPoint(x: x, y: y),
      size: CGSize(width: width, height: height)
    )

    if Self.debug { print("fieldOfView", fieldOfView) }

    let minX = (visibleWindows.map { $0.window.rect.minX }.min() ?? 0) + windowSpacing
    let maxX = (visibleWindows.map { $0.window.rect.maxX }.max() ?? 0) + windowSpacing
    let minY = (visibleWindows.map { $0.window.rect.minY }.min() ?? 0) + windowSpacing
    let maxY = (visibleWindows.map { $0.window.rect.maxY }.max() ?? 0) + windowSpacing

    var searching = true
    var match: SystemWindowModel?
    var constraint: (WindowModel) -> Bool

    var tiling: WindowTiling?
    if let screen = currentScreen(fieldOfView) {
      tiling = SystemWindowTilingRunner.calculateTiling(for: currentWindow.rect, in: screen.visibleFrame.mainDisplayFlipped)
    }

    while searching {
      rerouteDirectionIfNeeded(&direction, frame: fieldOfView, tiling: tiling, maxX: maxX, minY: minY, maxY: maxY)

      switch direction {
      case .left:
        fieldOfView.origin.x -= windowSpacing
        if fieldOfView.maxX < minX { searching = false }
        constraint = { abs($0.rect.origin.x - currentWindow.rect.origin.x) > windowSpacing }
      case .right:
        fieldOfView.origin.x += windowSpacing
        if fieldOfView.minX > maxX { searching = false }
        constraint = { abs($0.rect.origin.x - currentWindow.rect.origin.x) > windowSpacing }
      case .up:
        fieldOfView.origin.y -= windowSpacing
        if fieldOfView.maxY < minY { searching = false }
        constraint = { abs($0.rect.origin.y - currentWindow.rect.origin.y) > windowSpacing }
      case .down:
        fieldOfView.origin.y += windowSpacing
        if fieldOfView.minY > maxY { searching = false }
        constraint = { abs($0.rect.origin.y - currentWindow.rect.origin.y) > windowSpacing }
      }

      if Self.debug, let screen = currentScreen(fieldOfView) {
        let fieldOfView = fieldOfView
        Task { @MainActor in
          let invertedRect = fieldOfView.invertedYCoordinate(on: screen)
          windowController.window?.animator().setFrame(invertedRect, display: true)
          window.orderFrontRegardless()
        }
      }

      for visibleWindow in visibleWindows where visibleWindow.window != currentWindow {
        let constraintResult = constraint(visibleWindow.window)
        let intersectionResult = fieldOfView.intersects(visibleWindow.window.rect)
        if constraintResult && intersectionResult {
          match = visibleWindow
          searching = false
          break
        }
      }
    }

    if Self.debug {
      for window in visibleWindows {
        print("available window (\(window.index))", window.window.ownerName, window.window.rect)
      }
      print("--------------")
      print("currentWindow", currentWindow.ownerName, currentWindow.rect)
      print("match  (\(match?.index))", match?.window.ownerName, match?.window.rect)
      print("--------------")
    }

    guard let match else { return nil }


    return match.window
  }

  private func currentScreen(_ rect: CGRect) -> NSScreen? {
    let screen: NSScreen? = NSScreen.screens.first(where: { $0.visibleFrame.intersects(rect) })

    return screen
  }

  private func targetRect(on screen: NSScreen) -> CGRect {
    let size: CGFloat = 2
    let origin = CGPoint(x: screen.frame.midX - size, y: screen.frame.midY - size)
    let targetRect: CGRect = CGRect(origin: origin, size: CGSize(width: size, height: size))
    return targetRect
  }
}

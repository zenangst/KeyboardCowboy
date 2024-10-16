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
    let minX = currentScreen(frame).first?.visibleFrame.mainDisplayFlipped.origin.x ?? 0

    if direction == .left && frame.origin.x < minX {
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
      guard frame.minY < minY else { return }

      if tiling == .topLeft || tiling == .left {
        direction = .right
      } else {
        direction = .left
      }
    }
  }

  func findNextWindow(_ currentWindow: RelativeWindowModel, windows: [RelativeWindowModel],
                      direction: SystemWindowRelativeFocus.Direction,
                      initialScreen: NSScreen = NSScreen.main!) async -> RelativeWindowModel? {
    let initialDirection = direction
    let windowSpacing = max(min(CGFloat(UserDefaults(suiteName: "com.apple.WindowManager")?.float(forKey: "TiledWindowSpacing") ?? 8), 20), 1)
    var systemWindows = windows.systemWindows
      .sorted { $0.index < $1.index }

    if systemWindows.isEmpty { return nil }

    systemWindows.insert(RelativeSystemWindowModel(index: -1, window: currentWindow), at: 0)

    var occupiedRects = [CGRect]()
    var visibleWindows = [RelativeSystemWindowModel]()

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

    let width = currentWindow.rect.size.width / 3
    let height = currentWindow.rect.size.width / 3

    let y = switch direction {
    case .up:    currentWindow.rect.midY
    case .down:  currentWindow.rect.midY
    case .left:  currentWindow.rect.minY
    case .right: currentWindow.rect.minY
    }

    let x = switch direction {
    case .up:    currentWindow.rect.midX + width / 2
    case .down:  currentWindow.rect.midX - width / 2
    case .left:  currentWindow.rect.minX - width / 2
    case .right: currentWindow.rect.maxX + width / 2
    }

    var direction = initialDirection
    var fieldOfViewRect = CGRect(
      origin: CGPoint(x: x, y: y),
      size: CGSize(width: width, height: height)
    )

    let minX = (visibleWindows.map { $0.window.rect.minX }.min() ?? 0) + windowSpacing
    let maxX = (visibleWindows.map { $0.window.rect.maxX }.max() ?? 0) + windowSpacing
    let minY = (visibleWindows.map { $0.window.rect.minY }.min() ?? 0) + windowSpacing
    let maxY = (visibleWindows.map { $0.window.rect.maxY }.max() ?? 0) + windowSpacing

    var searching = true
    var match: RelativeSystemWindowModel?
    var constraint: (RelativeWindowModel) -> Bool

    var tiling: WindowTiling?
    if let screen = currentScreen(fieldOfViewRect).first {
      tiling = SystemWindowTilingRunner.calculateTiling(for: currentWindow.rect, in: screen.visibleFrame.mainDisplayFlipped)
    }

    while searching {
      rerouteDirectionIfNeeded(&direction, frame: fieldOfViewRect, tiling: tiling, maxX: maxX, minY: minY, maxY: maxY)

      let increment: CGFloat = 1
      switch direction {
      case .left:
        fieldOfViewRect.origin.x -= increment
        if fieldOfViewRect.maxX < minX - windowSpacing { searching = false }
        constraint = { abs($0.rect.origin.x - currentWindow.rect.origin.x) > windowSpacing }
      case .right:
        fieldOfViewRect.origin.x += increment
        if fieldOfViewRect.minX > maxX {
          searching = false
        }
        constraint = { abs($0.rect.origin.x - currentWindow.rect.origin.x) > windowSpacing }
      case .up:
        fieldOfViewRect.origin.y -= increment
        if fieldOfViewRect.maxY < minY { searching = false }
        constraint = { abs($0.rect.origin.y - currentWindow.rect.origin.y) > windowSpacing }
      case .down:
        fieldOfViewRect.origin.y += increment
        if fieldOfViewRect.minY > maxY {
          searching = false
        }
        constraint = { abs($0.rect.origin.y - currentWindow.rect.origin.y) > windowSpacing }
      }

      for visibleWindow in visibleWindows where visibleWindow.window != currentWindow {
        let constraintResult = constraint(visibleWindow.window)
        let intersectionResult = fieldOfViewRect.intersects(visibleWindow.window.rect)
        if constraintResult && intersectionResult {
          match = visibleWindow
          searching = false
          break
        }
      }
    }

    updateDebugWindow(fieldOfViewRect)

    if let match {
      return match.window
    } else {
      fieldOfViewRect.size = .init(width: initialScreen.visibleFrame.width / 2.5,
                                   height: initialScreen.visibleFrame.height / 2.5)
      switch initialDirection {
      case .up: #warning("Implement this.")
        break
      case .down: #warning("Implement this.")
        break
      case .left:
        fieldOfViewRect.origin.x = initialScreen.visibleFrame.minX - windowSpacing
        fieldOfViewRect.origin.y = initialScreen.visibleFrame.mainDisplayFlipped.midY
      case .right:
        fieldOfViewRect.origin.x = initialScreen.visibleFrame.maxX
        fieldOfViewRect.origin.y = initialScreen.visibleFrame.mainDisplayFlipped.midY
      }

      let applicableScreens = NSScreen.screens.filter( { $0.frame.intersects(fieldOfViewRect) })

      if let applicableScreen = applicableScreens.first {
        let searchAreaRect = CGRect(
          origin: CGPoint(x: applicableScreen.visibleFrame.width / 2,
                          y: applicableScreen.visibleFrame.height / 2),
          size: CGSize(width: applicableScreen.visibleFrame.mainDisplayFlipped.midX - fieldOfViewRect.width / 2,
                       height: applicableScreen.visibleFrame.mainDisplayFlipped.midY - fieldOfViewRect.height / 2)
        )

        updateDebugWindow(fieldOfViewRect)

        let match = windows.first(where: { $0.rect.intersects(fieldOfViewRect) })
        return match
      }
      return nil
    }
  }

  private func updateDebugWindow(_ frame: CGRect) {
    if Self.debug {
      Task { @MainActor in
        windowController.window?.animator().setFrame(frame.mainDisplayFlipped, display: true)
        window.orderFrontRegardless()
      }
    }
  }

  private func currentScreen(_ rect: CGRect) -> [NSScreen] {
    NSScreen.screens.filter( { $0.visibleFrame.intersects(rect) })
  }

  private func targetRect(on screen: NSScreen) -> CGRect {
    let size: CGFloat = 2
    let origin = CGPoint(x: screen.frame.midX - size, y: screen.frame.midY - size)
    let targetRect: CGRect = CGRect(origin: origin, size: CGSize(width: size, height: size))
    return targetRect
  }
}

extension Array<RelativeWindowModel> {
  var systemWindows: [RelativeSystemWindowModel] { enumerated().reduce(into: [], { result, entry in
    result.append(RelativeSystemWindowModel(index: entry.offset, window: entry.element))
  })
  }
}

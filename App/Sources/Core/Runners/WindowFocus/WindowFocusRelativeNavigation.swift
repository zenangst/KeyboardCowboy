import AppKit
import AXEssibility
import Bonzai
import Foundation
import SwiftUI
import Windows

@MainActor
final class WindowFocusRelativeNavigation: @unchecked Sendable {
  static var debug: Bool = false

  @MainActor
  private lazy var systemElement = SystemAccessibilityElement()

  @MainActor lazy var window: NSWindow = ZenWindow(
    animationBehavior: .none,
    content: RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 4),
  )
  @MainActor lazy var windowController: NSWindowController = .init(window: window)

  fileprivate func rerouteDirectionIfNeeded(_ direction: inout WindowFocusRelativeFocus.Direction, frame: CGRect,
                                            tiling: WindowTiling?, screen: NSScreen)
  {
    switch direction {
    case .up:
      if frame.minY >= screen.visibleFrame.minY { return }
    case .down:
      if frame.origin.y <= screen.visibleFrame.maxY { return }
    case .left:
      if frame.minX - frame.width / 2 >= screen.visibleFrame.minX { return }
    case .right:
      if frame.maxX + frame.width / 2 <= screen.visibleFrame.maxX { return }
    }

    switch tiling {
    case .left:
      switch direction {
      case .up, .down: direction = .right
      case .right: direction = .down
      case .left: break
      }
    case .right, .bottom:
      switch direction {
      case .up, .down: direction = .left
      case .left: direction = .down
      case .right: direction = .up
      }
    case .top:
      break
    case .topLeft:
      switch direction {
      case .down: direction = .right
      case .right: direction = .down
      case .up, .left: break
      }
    case .topRight:
      switch direction {
      case .down: direction = .left
      case .left: direction = .down
      case .up, .right: break
      }
    case .bottomLeft:
      switch direction {
      case .up: direction = .right
      case .right: direction = .up
      case .down, .left: break
      }
    case .bottomRight:
      switch direction {
      case .up: direction = .left
      case .left: direction = .up
      case .right, .down: break
      }
    default:
      break
    }
  }

  @MainActor
  func findNextWindow(_ currentWindow: RelativeWindowModel, windows: [RelativeWindowModel],
                      direction: WindowFocusRelativeFocus.Direction,
                      initialScreen: NSScreen = NSScreen.main!) async throws -> RelativeWindowModelMatch?
  {
    let initialDirection = direction
    let windowSpacing: CGFloat = if UserSettings.WindowManager.tiledWindowMarginsEnabled == false {
      0
    } else {
      UserSettings.WindowManager.tiledWindowSpacing
    }

    let systemWindows = windows.systemWindows
      .sorted { $0.index < $1.index }
      .filter { $0.window != currentWindow }

    if systemWindows.isEmpty { return nil }

    let width = max(min(1, windowSpacing), 50)
    let height = max(min(1, windowSpacing), 50)

    var x = currentWindow.rect.midX
    var y = currentWindow.rect.minY

    switch direction {
    case .up:
      y -= height / 2
      x += width
    case .down:
      x -= width
    case .left:
      x = currentWindow.rect.minX - width
    case .right:
      x = currentWindow.rect.maxX + width
    }

    var direction = initialDirection
    var fieldOfViewRect = CGRect(
      origin: CGPoint(x: x, y: y),
      size: CGSize(width: width, height: height),
    )

    let minX = (systemWindows.map(\.window.rect.minX).min() ?? 0) + windowSpacing
    let maxX = (systemWindows.map(\.window.rect.maxX).max() ?? 0) + windowSpacing
    let minY = (systemWindows.map(\.window.rect.minY).min() ?? 0) + windowSpacing
    let maxY = (systemWindows.map(\.window.rect.maxY).max() ?? 0) + windowSpacing

    var searching = true
    var constraint: (RelativeWindowModel) -> Bool = { _ in false }
    var tiling: WindowTiling?

    if let screen = currentScreen(fieldOfViewRect).first {
      tiling = WindowTilingRunner.calculateTiling(for: currentWindow.rect, in: screen.visibleFrame.mainDisplayFlipped)

      switch tiling {
      case .topLeft:
        fieldOfViewRect.origin.x = currentWindow.rect.minX + windowSpacing
      case .topRight:
        fieldOfViewRect.origin.x = currentWindow.rect.maxX - windowSpacing - fieldOfViewRect.width
      default:
        break
      }
    }

    do {
      let debugRect = fieldOfViewRect
      updateDebugWindow(debugRect)
    }

    while searching {
      try Task.checkCancellation()

      if Self.debug { try await Task.sleep(for: .seconds(0.0125)) }

      let increment: CGFloat = fieldOfViewRect.width
      switch direction {
      case .left:
        fieldOfViewRect.origin.x -= increment
        constraint = {
          !currentWindow.rect.contains($0.rect) &&
            $0.rect.origin.x < currentWindow.rect.origin.x &&
            abs($0.rect.origin.x - currentWindow.rect.origin.x) > 2
        }
        if fieldOfViewRect.maxX < minX - windowSpacing {
          searching = false
          break
        }
      case .right:
        fieldOfViewRect.origin.x += increment
        if fieldOfViewRect.minX > maxX {
          searching = false
          break
        }
        constraint = {
          !currentWindow.rect.contains($0.rect) &&
            $0.rect.origin.x > currentWindow.rect.origin.x &&
            $0.rect.maxX != currentWindow.rect.maxX &&
            abs($0.rect.origin.x - currentWindow.rect.origin.x) > 2
        }
      case .up:
        fieldOfViewRect.origin.y -= increment
        if fieldOfViewRect.maxY < minY {
          searching = false
          break
        }
        constraint = {
          !currentWindow.rect.contains($0.rect) &&
            $0.rect.origin.y != currentWindow.rect.origin.y &&
            abs($0.rect.origin.y - currentWindow.rect.origin.y) > 2
        }
      case .down:
        fieldOfViewRect.origin.y += increment
        if fieldOfViewRect.maxY + fieldOfViewRect.height >= maxY {
          searching = false
          break
        }
        constraint = {
          !currentWindow.rect.contains($0.rect) &&
            $0.rect.maxY != currentWindow.rect.maxY &&
            $0.rect.origin.y > currentWindow.rect.origin.y &&
            abs($0.rect.origin.y - currentWindow.rect.origin.y) > 2
        }
      }

      var deadzones = [CGRect]()
      var useDeadZones = false
      if UserSettings.WindowManager.tiledWindowSpacing > 0 {
        let mainFrame = NSScreen.main!.frame
        let horizontalDeadspace = CGRect(origin: CGPoint(x: mainFrame.minX,
                                                         y: mainFrame.midY),
                                         size: CGSize(width: mainFrame.width,
                                                      height: UserSettings.WindowManager.tiledWindowSpacing))
        let verticalDeadspace = CGRect(origin: CGPoint(x: mainFrame.midX - UserSettings.WindowManager.tiledWindowSpacing / 2,
                                                       y: mainFrame.minY),
                                       size: CGSize(width: UserSettings.WindowManager.tiledWindowSpacing,
                                                    height: mainFrame.height))
        deadzones.append(verticalDeadspace)
        deadzones.append(horizontalDeadspace)
        useDeadZones = true
      }

      // Use accessibility to verify the location of the window.
      let elementOrigin = CGPoint(x: fieldOfViewRect.midX, y: fieldOfViewRect.midY)

      var shouldSkip = false
      if useDeadZones {
        for deadzone in deadzones {
          if deadzone.contains(elementOrigin) {
            shouldSkip = true
          }
        }
      }

      if !shouldSkip, let accessWindow = systemElement.element(at: elementOrigin, as: AnyAccessibilityElement.self)?.window,
         let firstMatch = systemWindows.first(where: { $0.window.id == accessWindow.id })
      {
        updateDebugWindow(firstMatch.window.rect)
        return .init(firstMatch.window, axWindow: accessWindow)
      }

      for systemWindow in systemWindows {
        guard constraint(systemWindow.window) else {
          continue
        }
        guard fieldOfViewRect.intersects(systemWindow.window.rect) else {
          continue
        }
        guard let accessWindow = systemElement.element(at: elementOrigin, as: AnyAccessibilityElement.self)?.window,
              systemWindow.window.id == accessWindow.id
        else {
          continue
        }

        searching = false
        updateDebugWindow(systemWindow.window.rect)
        return .init(systemWindow.window)
      }

      do {
        let debugRect = fieldOfViewRect
        updateDebugWindow(debugRect)
      }

      if let screen = currentScreen(fieldOfViewRect).first {
        rerouteDirectionIfNeeded(&direction, frame: fieldOfViewRect, tiling: tiling, screen: screen)
      } else {
        searching = false
      }
    }

    try Task.checkCancellation()
    fieldOfViewRect.size = .init(width: initialScreen.visibleFrame.width / 2.5,
                                 height: initialScreen.visibleFrame.height / 2.5)

    if NSScreen.screens.count == 1 {
      fieldOfViewRect.origin.x = initialScreen.visibleFrame.minX - windowSpacing
      fieldOfViewRect.origin.y = initialScreen.visibleFrame.mainDisplayFlipped.midY
    } else {
      switch initialDirection {
      case .up: #warning("Implement this.")
      case .down: #warning("Implement this.")
      case .left:
        fieldOfViewRect.origin.x = initialScreen.visibleFrame.minX - windowSpacing - fieldOfViewRect.width
        fieldOfViewRect.origin.y = initialScreen.visibleFrame.mainDisplayFlipped.midY
      case .right:
        fieldOfViewRect.origin.x = initialScreen.visibleFrame.maxX + windowSpacing + fieldOfViewRect.width
        fieldOfViewRect.origin.y = initialScreen.visibleFrame.mainDisplayFlipped.midY
      }
    }

    let applicableScreens = NSScreen.screens.filter { $0.frame.intersects(fieldOfViewRect) }
    if let nextScreen = applicableScreens.first {
      fieldOfViewRect.origin.x = nextScreen.frame.midX - fieldOfViewRect.size.width / 2
      fieldOfViewRect.origin.y = nextScreen.frame.mainDisplayFlipped.midY - fieldOfViewRect.size.height / 2

      do {
        let debugRect = fieldOfViewRect
        updateDebugWindow(debugRect)
      }

      let paddedWindowRect = currentWindow.rect.insetBy(dx: -2, dy: -2)

      if let match = windows
        .sorted(by: {
          if initialDirection == .left {
            $0.rect.minX < $1.rect.minX
          } else {
            $1.rect.maxX < $1.rect.maxX
          }
        })
        .first(where: { window in
          window != currentWindow &&
            !paddedWindowRect.contains(window.rect) &&
            window.rect.intersects(fieldOfViewRect)
        })
      {
        switch initialDirection {
        case .up, .down:
          if currentWindow.rect.origin.y == match.rect.origin.y { return nil }
        case .left, .right:
          if currentWindow.rect.origin.x == match.rect.origin.x { return nil }
        }
        updateDebugWindow(match.rect)
        return .init(match)
      }
    }
    return nil
  }

  private func updateDebugWindow(_ frame: @autoclosure @escaping @Sendable () -> CGRect) {
    if Self.debug {
      Task { @MainActor in
        windowController.window?.animator().setFrame(frame().mainDisplayFlipped, display: true)
        window.orderFrontRegardless()
      }
    }
  }

  private func currentScreen(_ rect: CGRect) -> [NSScreen] {
    NSScreen.screens.filter { $0.visibleFrame.mainDisplayFlipped.intersects(rect) }
  }

  private func targetRect(on screen: NSScreen) -> CGRect {
    let size: CGFloat = 2
    let origin = CGPoint(x: screen.frame.midX - size, y: screen.frame.midY - size)
    let targetRect = CGRect(origin: origin, size: CGSize(width: size, height: size))
    return targetRect
  }
}

extension [RelativeWindowModel] {
  var systemWindows: [RelativeSystemWindowModel] { enumerated().reduce(into: []) { result, entry in
    result.append(RelativeSystemWindowModel(index: entry.offset, window: entry.element))
  }
  }
}

struct RelativeWindowModelMatch {
  let axWindow: WindowAccessibilityElement?
  let window: RelativeWindowModel

  init(_ window: RelativeWindowModel, axWindow: WindowAccessibilityElement? = nil) {
    self.axWindow = axWindow
    self.window = window
  }
}

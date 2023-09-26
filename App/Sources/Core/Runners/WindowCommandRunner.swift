import AXEssibility
import Cocoa
import Foundation

enum WindowCommandRunnerError: Error {
  case unableToResolveFrontmostApplication
  case unabelToResolveWindowFrame
}

final class WindowCommandRunner {
  private var centerCache = [CGWindowID: CGRect]()
  private var fullscreenCache = [CGWindowID: CGRect]()
  private var task: Task<Void, Error>? {
    willSet {
      task?.cancel()
    }
  }

  @MainActor
  func run(_ command: WindowCommand) async throws {
    guard let currentScreen = NSScreen.main,
          let mainDisplay = NSScreen.mainDisplay else { return }

    try getFocusedWindow {
      activeWindow,
      originFrame in
      let newFrame: CGRect
      switch command.kind {
      case .decreaseSize(let byValue, let direction, let constrainedToScreen):
        newFrame = WindowRunnerDecreaseWindowSize
          .calulateRect(
            originFrame,
            byValue: byValue,
            in: direction,
            constrainedToScreen: constrainedToScreen,
            currentScreen: currentScreen,
            mainDisplay: mainDisplay
          )
      case .increaseSize(let byValue, let direction, let constrainedToScreen):
        newFrame = WindowRunnerIncreaseWindowSize
          .calulateRect(
            originFrame,
            byValue: byValue,
            in: direction,
            constrainedToScreen: constrainedToScreen,
            currentScreen: currentScreen,
            mainDisplay: mainDisplay
          )
      case .move(let byValue, let direction, let constrainedToScreen):
        newFrame = WindowRunnerMoveWindow
          .calulateRect(
            originFrame,
            byValue: byValue,
            in: direction,
            constrainedToScreen: constrainedToScreen,
            currentScreen: currentScreen,
            mainDisplay: mainDisplay
          )
      case .fullscreen(let padding):
        let resolvedFrame = WindowRunnerFullscreen
          .calulateRect(originFrame, currentScreen: currentScreen, 
                        mainDisplay: mainDisplay)
        
        let lhs = resolvedFrame.origin.x + resolvedFrame.origin.y + resolvedFrame.width + resolvedFrame.size.height + statusBarHeight()
        let rhs = originFrame.origin.x + originFrame.origin.y + originFrame.width + originFrame.size.height
        let delta = abs(lhs - rhs)
        let limit = currentScreen.visibleFrame.height - currentScreen.frame.height
        
        if delta <= abs(limit),
           let restoreFrame = fullscreenCache[activeWindow.id] {
          newFrame = restoreFrame
        } else {
          newFrame = resolvedFrame
          fullscreenCache[activeWindow.id] = originFrame
        }
      case .center:
        let resolvedFrame = WindowRunnerCenterWindow
          .calulateRect(originFrame, currentScreen: currentScreen, mainDisplay: mainDisplay)
        
        let lhs = resolvedFrame.origin.x + resolvedFrame.origin.y
        let rhs = originFrame.origin.x + originFrame.origin.y
        let delta = abs(lhs - rhs)
        
        if delta < 1,
           let restoreFrame = centerCache[activeWindow.id] {
          newFrame = restoreFrame
        } else {
          newFrame = resolvedFrame
          centerCache[activeWindow.id] = originFrame
        }
      case .moveToNextDisplay(let mode):
        switch mode {
        case .center:
          var nextScreen: NSScreen? = NSScreen.screens.first
          var foundMain: Bool = false
          for screen in NSScreen.screens {
            if foundMain {
              nextScreen = screen
              break
            } else if currentScreen == nextScreen {
              foundMain = true
            }
          }

          guard let nextScreen else { return }

          newFrame = WindowRunnerCenterWindow
            .calulateRect(originFrame, currentScreen: nextScreen, mainDisplay: mainDisplay)
        case .relative:
          newFrame = WindowRunnerMoveToNextDisplayRelative
            .calulateRect(originFrame, currentScreen: currentScreen, mainDisplay: mainDisplay)
        }
      }

      interpolateWindowFrame(
        from: originFrame,
        to: newFrame,
        duration: command.animationDuration,
        onUpdate: { activeWindow.frame = $0 }
      )
    }
  }

  // MARK: Private methods

  private func statusBarHeight() -> CGFloat {
    NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
      .button?
      .window?
      .frame
      .height ?? 0
  }

  private func statusBarThickness() -> CGFloat {
    NSStatusBar.system.thickness
  }

  private func statusBarHeightAndSystemThickness() -> CGFloat {
    statusBarHeight() + statusBarThickness()
  }

  private func getFocusedWindow(_ then: (WindowAccessibilityElement, CGRect) throws -> Void) throws {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      throw WindowCommandRunnerError.unableToResolveFrontmostApplication
    }

    let app = AppAccessibilityElement(frontmostApplication.processIdentifier)

    var previousValue: Bool = false
    if app.enhancedUserInterface == true {
      app.enhancedUserInterface = false
      previousValue = true
    }

    let focusedWindow = try app.focusedWindow()

    guard let windowFrame = focusedWindow.frame else {
      app.enhancedUserInterface = previousValue
      throw WindowCommandRunnerError.unabelToResolveWindowFrame
    }

    try then(focusedWindow, windowFrame)

    app.enhancedUserInterface = previousValue
  }

  @MainActor
  private func interpolateWindowFrame(from oldFrame: CGRect, to newFrame: CGRect,
                                      curve: InterpolationCurve = .easeInOut,
                                      duration: TimeInterval, onUpdate: @MainActor @escaping (CGRect) -> Void) {
    if duration == 0 {
      onUpdate(newFrame)
      return
    }

    self.task = Task {
      await withThrowingTaskGroup(of: Void.self) { group in
        let numberOfFrames = Int(duration * 60)
        for frameIndex in 0...numberOfFrames {
          group.addTask {
            let progress = CGFloat(frameIndex) / CGFloat(numberOfFrames)
            let easedProgress: CGFloat

            switch curve {
            case .easeIn:
              easedProgress = Self.easeIn(progress)
            case .easeInOut:
              easedProgress = Self.easeInOut(progress)
            case .spring:
              easedProgress = Self.spring(progress)
            case .linear:
              easedProgress = progress
            }

            let interpolatedOrigin = CGPoint(x: Self.interpolate(from: oldFrame.origin.x, to: newFrame.origin.x, progress: easedProgress),
                                             y: Self.interpolate(from: oldFrame.origin.y, to: newFrame.origin.y, progress: easedProgress))
            let interpolatedSize = CGSize(width: Self.interpolate(from: oldFrame.size.width, to: newFrame.size.width, progress: easedProgress),
                                          height: Self.interpolate(from: oldFrame.size.height, to: newFrame.size.height, progress: easedProgress))
            let interpolatedFrame = CGRect(origin: interpolatedOrigin, size: interpolatedSize)
            let delay = (duration / TimeInterval(numberOfFrames)) * TimeInterval(frameIndex)
            try await Task.sleep(for: .seconds(delay))
            try Task.checkCancellation()
            await onUpdate(interpolatedFrame)
          }
        }
      }
    }
  }

  private static func interpolate(from oldValue: CGFloat, to newValue: CGFloat, progress: CGFloat) -> CGFloat {
    return round(oldValue + (newValue - oldValue) * progress)
  }

  private static func easeInOut(_ t: CGFloat) -> CGFloat {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
  }

  private static func spring(_ t: CGFloat, mass: CGFloat = 1.0, damping: CGFloat = 1.0) -> CGFloat {
    return (1 - cos(t * CGFloat.pi * 4)) * pow(2, -damping * t) + 1
  }

  private static func easeIn(_ t: CGFloat) -> CGFloat {
    return t * t
  }
}

fileprivate enum InterpolationCurve {
  case easeIn
  case easeInOut
  case spring
  case linear
}

enum DockPosition: Int {
  case bottom = 0
  case left = 1
  case right = 2
}

func getDockPosition(_ screen: NSScreen) -> DockPosition {
  if screen.visibleFrame.origin.y == screen.frame.origin.y {
    if screen.visibleFrame.origin.x == screen.frame.origin.x {
      return .right
    } else {
      return .left
    }
  } else {
    return .bottom
  }
}

func getDockSize(_ screen: NSScreen) -> CGFloat {
  switch getDockPosition(screen) {
  case .right:
    return screen.frame.width - screen.visibleFrame.width
  case .left:
    return screen.visibleFrame.origin.x
  case .bottom:
    if screen.isMainDisplay {
      return screen.visibleFrame.origin.y
    } else {
      return abs(screen.visibleFrame.height - screen.frame.size.height)
    }
  }
}

func isDockHidden(_ screen: NSScreen) -> Bool {
  getDockSize(screen) < 25
}

extension NSScreen {
  // Different from `NSScreen.main`, the `mainDisplay` sets the conditions for the
  // coordinate system. All other screens have a coordinate space that is relative
  // to the main screen.
  var isMainDisplay: Bool { frame.origin == .zero }
  static var mainDisplay: NSScreen? { screens.first(where: { $0.isMainDisplay }) }

  static func screenContaining(_ rect: CGRect) -> NSScreen? {
    NSScreen.screens.first(where: { $0.frame.contains(rect) })
  }

  static var maxY: CGFloat {
    var maxY = 0.0 as CGFloat
    for screen in screens {
      maxY = CGFloat.maximum(screen.frame.maxY, maxY)
    }
    return maxY
  }
}

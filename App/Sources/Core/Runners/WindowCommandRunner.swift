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
    switch command.kind {
    case .decreaseSize(let byValue, let direction, let value):
      try decreaseSize(byValue, in: direction, constrainedToScreen: value, animationDuration: command.animationDuration)
    case .increaseSize(let byValue, let direction, let value):
      try increaseSize(byValue, in: direction, constrainedToScreen: value, animationDuration: command.animationDuration)
    case .move(let toValue, let direction, let value):
      try move(toValue, in: direction, constrainedToScreen: value, animationDuration: command.animationDuration)
    case .fullscreen(let padding):
      try fullscreen(with: padding, animationDuration: command.animationDuration)
    case .center:
      try center(animationDuration: command.animationDuration)
    case .moveToNextDisplay(let mode):
      try moveToNextDisplay(mode)
    }
  }

  // MARK: Private methods

  @MainActor
  private func center(_ screen: NSScreen? = NSScreen.main, animationDuration: Double) throws {
    guard let currentScreen = screen,
          let mainScreen = NSScreen.mainDisplay else { return }
    try getFocusedWindow { activeWindow, originFrame in
      let dockSize = getDockSize(currentScreen)
      let dockPosition = getDockPosition(currentScreen)
      let x: CGFloat
      let y: CGFloat
      let newFrame: CGRect
      if currentScreen == mainScreen {
        // Handle main screen
        x = CGFloat.formula(currentScreen.frame.origin.x) { fn in
          fn.add(currentScreen.frame.width / 2)
          fn.subtract(originFrame.width / 2)
          fn.add({ dockPosition == .left ? dockSize / 2 : 0 }())
          fn.subtract({ dockPosition == .right ? dockSize / 2 : 0 }())
        }
        y = CGFloat.formula(currentScreen.frame.maxY) { fn in
          fn.subtract(currentScreen.visibleFrame.height / 2)
          fn.subtract(originFrame.height / 2)
          fn.subtract({ dockPosition == .bottom ? dockSize : 0 }())
        }

        newFrame = CGRect(origin: CGPoint(x: x, y: y), size: originFrame.size)

        interpolateWindowFrame(
          from: originFrame,
          to: newFrame,
          duration: animationDuration,
          onUpdate: { activeWindow.frame = $0 }
        )
      } else {
        // Handle secondary screens
        x = CGFloat.formula(currentScreen.frame.origin.x) { fn in
          fn.add(currentScreen.frame.width / 2)
          fn.subtract(originFrame.width / 2)
          fn.add({ dockPosition == .left ? dockSize / 2 : 0 }())
          fn.subtract({ dockPosition == .right ? dockSize / 2 : 0 }())
        }

        y = CGFloat.formula(mainScreen.frame.maxY) { fn in
          fn.subtract(currentScreen.visibleFrame.origin.y)
          fn.subtract(originFrame.height)
          fn.subtract({ (currentScreen.frame.size.height - originFrame.size.height) / 2 }())
          fn.add({ dockPosition == .bottom ? dockSize / 2 : 0 }())
        }

        newFrame = CGRect(origin: CGPoint(x: x, y: y), size: originFrame.size)
      }

      let lhs = newFrame.origin.x + newFrame.origin.y
      let rhs = originFrame.origin.x + originFrame.origin.y
      let delta = abs(lhs - rhs)

      if delta < 1, let restoreFrame = centerCache[activeWindow.id] {
        interpolateWindowFrame(
          from: originFrame,
          to: restoreFrame,
          duration: animationDuration,
          onUpdate: { activeWindow.frame = $0 }
        )
      } else {
        interpolateWindowFrame(
          from: originFrame,
          to: newFrame,
          duration: animationDuration,
          onUpdate: { activeWindow.frame = $0 }
        )
        centerCache[activeWindow.id] = originFrame
      }
    }
  }

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

  @MainActor
  private func fullscreen(with padding: Int, animationDuration: Double) throws {
    guard let currentScreen = NSScreen.main,
          let mainScreen = NSScreen.mainDisplay else { return }

    try getFocusedWindow { activeWindow, originFrame in
      let dockSize = getDockSize(currentScreen)
      let dockPosition = getDockPosition(currentScreen)
      let x: CGFloat
      let y: CGFloat
      let size = CGSize(width: currentScreen.visibleFrame.width,
                        height: currentScreen.visibleFrame.height)
      let newFrame: CGRect

      if currentScreen == mainScreen {
        x = CGFloat.formula(currentScreen.frame.origin.x) { fn in }
        y = CGFloat.formula(currentScreen.frame.origin.y) { fn in
          fn.add(currentScreen.visibleFrame.height)
          fn.subtract(size.height)
          fn.subtract({ dockPosition == .bottom ? dockSize : 0 }())
        }

        newFrame = CGRect(origin: CGPoint(x: x, y: y), size: size)
      } else {
        // Handle secondary screens
        x = CGFloat.formula(currentScreen.frame.origin.x) { fn in }
        y = CGFloat.formula(mainScreen.frame.maxY) { fn in
          fn.subtract(currentScreen.visibleFrame.origin.y)
          fn.subtract(size.height)
        }
        newFrame = CGRect(origin: CGPoint(x: x, y: y), size: size)
      }

      let lhs = newFrame.origin.x + newFrame.origin.y + newFrame.width + newFrame.size.height + statusBarHeight()
      let rhs = originFrame.origin.x + originFrame.origin.y + originFrame.width + originFrame.size.height
      let delta = abs(lhs - rhs)
      let limit = currentScreen.visibleFrame.height - currentScreen.frame.height

      if delta <= abs(limit), let restoreFrame = fullscreenCache[activeWindow.id] {
        interpolateWindowFrame(
          from: originFrame,
          to: restoreFrame,
          duration: animationDuration,
          onUpdate: { activeWindow.frame = $0 }
        )
      } else {
        interpolateWindowFrame(
          from: originFrame,
          to: newFrame,
          duration: animationDuration,
          onUpdate: { activeWindow.frame = $0 }
        )
        fullscreenCache[activeWindow.id] = originFrame
      }
    }
  }

  @MainActor
  private func move(_ byValue: Int, in direction: WindowCommand.Direction,
                    constrainedToScreen: Bool,
                    animationDuration: Double) throws {
    guard let mainScreen = NSScreen.main else { return }

    let newValue = CGFloat(byValue)
    let dockSize = getDockSize(mainScreen)
    let dockPosition = getDockPosition(mainScreen)

    try getFocusedWindow { window, newWindowFrame in
      var newWindowFrame = newWindowFrame
      let oldWindowFrame = newWindowFrame

      switch direction {
      case .leading:
        newWindowFrame.origin.x -= newValue
      case .topLeading:
        newWindowFrame.origin.x -= newValue
        newWindowFrame.origin.y -= newValue
      case .top:
        newWindowFrame.origin.y -= newValue
      case .topTrailing:
        newWindowFrame.origin.x += newValue
        newWindowFrame.origin.y -= newValue
      case .trailing:
        newWindowFrame.origin.x += newValue
      case .bottomTrailing:
        newWindowFrame.origin.x += newValue
        newWindowFrame.origin.y += newValue
      case .bottom:
        newWindowFrame.origin.y += newValue
      case .bottomLeading:
        newWindowFrame.origin.y += newValue
        newWindowFrame.origin.x -= newValue
      }

      var dockRightSize: CGFloat = 0
      var dockBottomSize: CGFloat = 0
      var dockLeftSize: CGFloat = 0

      let currentScreen: NSScreen
      if constrainedToScreen {
        currentScreen = NSScreen.screenContaining(oldWindowFrame) ?? mainScreen
      } else {
        currentScreen = mainScreen
      }

      switch dockPosition {
      case .bottom:
        dockBottomSize = dockSize
      case .left:
        dockLeftSize = dockSize
      case .right:
        dockRightSize = dockSize
      }

      // MARK: - TODO: Rewrite this method with the help of the math functions.

      if constrainedToScreen {
        if newWindowFrame.maxX >= currentScreen.frame.maxX - dockRightSize {
          newWindowFrame.origin.x = currentScreen.frame.maxX - newWindowFrame.size.width - dockRightSize
        } else if newWindowFrame.origin.x <= currentScreen.frame.origin.x + dockLeftSize {
          newWindowFrame.origin.x = currentScreen.frame.origin.x + dockLeftSize
        } else if newWindowFrame.origin.x < currentScreen.frame.origin.x {
          newWindowFrame.origin.x = currentScreen.frame.origin.x
        }

        if currentScreen.isMainDisplay {
          if newWindowFrame.maxY >= currentScreen.frame.maxY - dockBottomSize {
            newWindowFrame.origin.y = currentScreen.frame.maxY - newWindowFrame.size.height
            newWindowFrame.origin.y -= dockBottomSize
          } else if newWindowFrame.origin.y >= currentScreen.visibleFrame.maxY {
            newWindowFrame.origin.y = currentScreen.visibleFrame.maxY
          }
        } else {
          if currentScreen.frame.origin.y > 0 {
            // The second screen is above the main display.
            let zeroPoint = -abs(currentScreen.frame.origin.y) - statusBarHeightAndSystemThickness()
            let prototype = CGRect(origin: .init(x: 0, y: zeroPoint), size: currentScreen.frame.size)
            let maxY = prototype.origin.y + currentScreen.frame.height - newWindowFrame.height
            newWindowFrame.origin.y = min(newWindowFrame.origin.y, maxY)
          } else {
            // The second screen is below the main display.
            let zeroPoint = abs(currentScreen.frame.origin.y) - statusBarHeight()
            let prototype = CGRect(origin: .init(x: 0, y: zeroPoint), size: currentScreen.frame.size)
            let maxY = prototype.origin.y + currentScreen.frame.height - newWindowFrame.height - statusBarHeight()
            newWindowFrame.origin.y = min(newWindowFrame.origin.y, maxY)
          }
        }
      }

      interpolateWindowFrame(from: oldWindowFrame, to: newWindowFrame, duration: animationDuration) { newRect in
        window.frame?.origin = newRect.origin
      }
    }
  }

  @MainActor
  private func increaseSize(_ byValue: Int, in direction: WindowCommand.Direction,
                            constrainedToScreen: Bool, animationDuration: Double) throws {
    guard let screen = NSScreen.main else { return }

    try getFocusedWindow { window, newWindowFrame in
      let newValue = CGFloat(byValue)
      var newWindowFrame = newWindowFrame
      let oldWindowFrame = newWindowFrame

      switch direction {
      case .leading:
        newWindowFrame.origin.x -= newValue
        newWindowFrame.size.width += newValue
      case .topLeading:
        newWindowFrame.origin.x -= newValue
        newWindowFrame.size.width += newValue
        newWindowFrame.origin.y -= newValue
        newWindowFrame.size.height += newValue
      case .top:
        newWindowFrame.origin.y -= newValue
        newWindowFrame.size.height += newValue
      case .topTrailing:
        newWindowFrame.origin.y -= newValue
        newWindowFrame.size.height += newValue
        newWindowFrame.size.width += newValue
      case .trailing:
        newWindowFrame.size.width += newValue
      case .bottomTrailing:
        newWindowFrame.size.width += newValue
        newWindowFrame.size.height += newValue
      case .bottom:
        newWindowFrame.size.height += newValue
      case .bottomLeading:
        newWindowFrame.origin.x -= newValue
        newWindowFrame.size.width += newValue
        newWindowFrame.size.height += newValue
      }

      if constrainedToScreen {
        newWindowFrame.origin.x = max(screen.frame.origin.x, newWindowFrame.origin.x)
      }

      interpolateWindowFrame(from: oldWindowFrame, to: newWindowFrame, duration: animationDuration) { newRect in
        window.frame = newRect
      }
    }
  }

  @MainActor
  private func decreaseSize(_ byValue: Int, in direction: WindowCommand.Direction,
                            constrainedToScreen: Bool,
                            animationDuration: Double) throws {
    try getFocusedWindow { window, newWindowFrame in
      let newValue = CGFloat(byValue)
      var newWindowFrame = newWindowFrame
      let oldWindowFrame = newWindowFrame

      switch direction {
      case .leading:
        newWindowFrame.origin.x += newValue
        newWindowFrame.size.width -= newValue

        interpolateWindowFrame(from: oldWindowFrame, to: newWindowFrame, duration: animationDuration) { newRect in
          window.frame = newRect
          if window.frame?.width != newWindowFrame.width {
            window.frame?.origin.x = oldWindowFrame.origin.x
          }
        }
      case .topLeading:
        newWindowFrame.size.width -= newValue
        newWindowFrame.size.height -= newValue
        interpolateWindowFrame(from: oldWindowFrame, to: newWindowFrame, duration: animationDuration) { newRect in
          window.frame = newRect
        }
      case .top:
        newWindowFrame.size.height -= newValue
        window.frame = newWindowFrame
      case .topTrailing:
        newWindowFrame.origin.x += newValue
        newWindowFrame.size.height -= newValue
        newWindowFrame.size.width -= newValue
        interpolateWindowFrame(from: oldWindowFrame, to: newWindowFrame, duration: animationDuration) { newRect in
          window.frame = newRect
          if window.frame?.width != newWindowFrame.width {
            window.frame?.origin = oldWindowFrame.origin
          }
        }
      case .trailing:
        newWindowFrame.size.width -= newValue
        interpolateWindowFrame(from: oldWindowFrame, to: newWindowFrame, duration: animationDuration) { newRect in
          window.frame = newRect
        }
      case .bottomTrailing:
        newWindowFrame.origin.x += newValue
        newWindowFrame.origin.y += newValue
        newWindowFrame.size.width -= newValue
        newWindowFrame.size.height -= newValue
        interpolateWindowFrame(from: oldWindowFrame, to: newWindowFrame, duration: animationDuration) { newRect in
          window.frame = newRect
        }
      case .bottom:
        newWindowFrame.origin.y += newValue
        newWindowFrame.size.height -= newValue
        interpolateWindowFrame(from: oldWindowFrame, to: newWindowFrame, duration: animationDuration) { newRect in
          window.frame = newRect
        }
      case .bottomLeading:
        newWindowFrame.origin.y += newValue
        newWindowFrame.size.width -= newValue
        newWindowFrame.size.height -= newValue
        interpolateWindowFrame(from: oldWindowFrame, to: newWindowFrame, duration: animationDuration) { newRect in
          window.frame = newRect
          if window.frame?.width != newWindowFrame.width {
            window.frame?.origin = oldWindowFrame.origin
          }
        }
      }
    }
  }

  @MainActor
  private func moveToNextDisplay(_ mode: WindowCommand.Mode) throws {
    guard let mainScreen = NSScreen.main else { return }

    var nextScreen: NSScreen? = NSScreen.screens.first
    var foundMain: Bool = false
    for screen in NSScreen.screens {
      if foundMain {
        nextScreen = screen
        break
      } else if mainScreen == nextScreen {
        foundMain = true
      }
    }

    guard let nextScreen else { return }

    try getFocusedWindow { window, windowFrame in
      switch mode {
      case .center:
        window.frame?.origin.x = nextScreen.frame.origin.x
        try self.center(nextScreen, animationDuration: 0.0)
      case .relative:
        let currentFrame = mainScreen.frame
        let nextFrame = nextScreen.frame
        var windowFrame = windowFrame

        let scaleWidthFactor = nextFrame.width / currentFrame.width
        let scaleHeightFactor = nextFrame.height / currentFrame.height


        let zeroPoint: CGFloat
        if currentFrame.origin.y > nextFrame.origin.y {
          zeroPoint = -abs(currentFrame.origin.y)
        } else {
          zeroPoint = abs(currentFrame.origin.y)
        }

        let maxY = currentFrame.height - abs(zeroPoint)
        let current = windowFrame.origin.y / maxY
        let newY = (nextFrame.size.height - windowFrame.size.height) * current

        windowFrame.size.width *= scaleWidthFactor
        windowFrame.size.height *= scaleHeightFactor
        windowFrame.origin.y = newY
        windowFrame.origin.x = (windowFrame.origin.x - currentFrame.origin.x) * scaleWidthFactor + nextFrame.origin.x

        window.frame = windowFrame
      }
    }
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

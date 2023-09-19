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
    guard let screen = screen else { return }

    let (window, windowFrame) = try getFocusedWindow()
    let screenFrame = screen.frame
    let menubarOffset = abs(screen.visibleFrame.size.height - screen.frame.size.height)
    let x: Double = screenFrame.midX - (windowFrame.width / 2)
    let y: Double = screenFrame.midY - (windowFrame.height / 2) + menubarOffset / 2
    var newRect = CGRect(x: x, y: y, width: windowFrame.width, height: windowFrame.height)

    if !screen.isMainDisplay {
      // TODO: Verify that this works.
      if screen.frame.origin.y < 0 {
        newRect = invert(newRect)
      } else {
        // TODO: This needs work
        newRect.origin.y = screenFrame.origin.y - windowFrame.height
      }
    }

    let deltaX = windowFrame.origin.x - newRect.origin.x
    let deltaY = windowFrame.origin.y - newRect.origin.y
    let shouldToggleX = deltaX >= -1 && deltaX <= 1
    let shouldToggleY = deltaY >= -1 && deltaY <= 1

    if let cachedRect = centerCache[window.id], shouldToggleX, shouldToggleY {
      interpolateWindowFrame(from: windowFrame,
                             to: cachedRect,
                             curve: .easeInOut,
                             duration: animationDuration,
                             onUpdate: { newRect in
        window.frame?.origin = newRect.origin
      })
    } else {
      interpolateWindowFrame(from: windowFrame,
                             to: newRect,
                             curve: .easeInOut,
                             duration: animationDuration,
                             onUpdate: { newRect in
        window.frame?.origin = newRect.origin
      })
      centerCache[window.id] = windowFrame
    }
  }

  private func statusBarHeight() -> CGFloat {
    let statusBarHeight = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
      .button?
      .window?
      .frame
      .height ?? 0
    return statusBarHeight + NSStatusBar.system.thickness
  }

  @MainActor
  private func fullscreen(with padding: Int, animationDuration: Double) throws {
    guard let screen = NSScreen.main else { return }
    let (window, windowFrame) = try getFocusedWindow()

    let value: CGFloat
    if padding > 1 {
      value = CGFloat(padding / 2)
    } else {
      value = 0
    }

    var newValue = screen.visibleFrame.insetBy(dx: value, dy: value)
    let dockSize = getDockSize(screen)
    if getDockPosition(screen) == .bottom { newValue.origin.y -= dockSize }
    let delta = ((window.frame?.size.width) ?? 0) - newValue.size.width
    let shouldToggle = delta >= -1 && delta <= 1
    if shouldToggle, let cachedFrame = fullscreenCache[window.id] {
      interpolateWindowFrame(from: windowFrame, to: cachedFrame, curve: .easeIn, duration: animationDuration) { newRect in
        window.frame = newRect
      }
    } else {
      let statusBarHeight = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        .button?
        .window?
        .frame
        .height ?? 0
      newValue.origin.y += statusBarHeight + NSStatusBar.system.thickness

      if screen.frame.origin.y < 0 {
        newValue = invert(newValue)
      } else {
        newValue.origin.y = -abs(screen.frame.origin.y)
      }

      interpolateWindowFrame(from: windowFrame, to: newValue, curve: .easeIn, duration: animationDuration) { newRect in
        window.frame = newRect
      }

      fullscreenCache[window.id] = windowFrame
    }
  }

  @MainActor
  private func move(_ byValue: Int, in direction: WindowCommand.Direction,
                    constrainedToScreen: Bool,
                    animationDuration: Double) throws {
    guard let screen = NSScreen.main else { return }

    let newValue = CGFloat(byValue)
    let dockSize = getDockSize(screen)
    let dockPosition = getDockPosition(screen)
    var (window, newWindowFrame) = try getFocusedWindow()
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
      currentScreen = NSScreen.screenContaining(oldWindowFrame) ?? screen
    } else {
      currentScreen = screen
    }

    switch dockPosition {
    case .bottom:
      dockBottomSize = dockSize
    case .left:
      dockLeftSize = dockSize
    case .right:
      dockRightSize = dockSize
    }

    if constrainedToScreen {
      if newWindowFrame.maxX >= currentScreen.frame.maxX - dockRightSize {
        newWindowFrame.origin.x = currentScreen.frame.maxX - newWindowFrame.size.width - dockRightSize
      } else if newWindowFrame.origin.x <= currentScreen.frame.origin.x + dockLeftSize {
        newWindowFrame.origin.x = currentScreen.frame.origin.x + dockLeftSize
      } else if newWindowFrame.origin.x < currentScreen.frame.origin.x {
        newWindowFrame.origin.x = currentScreen.frame.origin.x
      }

      if currentScreen.isMainDisplay {
        if newWindowFrame.maxY >= screen.frame.maxY - dockBottomSize {
          newWindowFrame.origin.y = screen.frame.maxY - newWindowFrame.size.height
          newWindowFrame.origin.y -= dockBottomSize
        } else if newWindowFrame.origin.y >= screen.visibleFrame.maxY {
          newWindowFrame.origin.y = screen.visibleFrame.maxY
        }
      } else {
        if currentScreen.frame.origin.y >= 0 {
        } else {
          print(newWindowFrame)
//          let invertedFrame = invert(newWindowFrame)
//          if invertedFrame.origin.y <= currentScreen.frame.origin.y {
//            newWindowFrame.origin.y = currentScreen.frame.maxY + dockBottomSize + statusBarHeight()
//          }
        }
      }
    }


    interpolateWindowFrame(from: oldWindowFrame, to: newWindowFrame, duration: animationDuration) { newRect in
      window.frame?.origin = newRect.origin
    }
  }

  @MainActor
  private func increaseSize(_ byValue: Int, in direction: WindowCommand.Direction,
                            constrainedToScreen: Bool, animationDuration: Double) throws {
    guard let screen = NSScreen.main else { return }
    let newValue = CGFloat(byValue)
    var (window, newWindowFrame) = try getFocusedWindow()
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

  @MainActor
  private func decreaseSize(_ byValue: Int, in direction: WindowCommand.Direction,
                            constrainedToScreen: Bool,
                            animationDuration: Double) throws {
    let newValue = CGFloat(byValue)
    var (window, newWindowFrame) = try getFocusedWindow()
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
    let (window, windowFrame) = try getFocusedWindow()


    switch mode {
    case .center:
      window.frame?.origin.x = nextScreen.frame.origin.x
      try self.center(nextScreen, animationDuration: 0.0)
    case .relative:
      let currentFrame = mainScreen.frame
      let nextFrame = nextScreen.frame
      var windowFrame = windowFrame

      // Make window frame relative to the next frame
      windowFrame.origin.x -= currentFrame.origin.x
      windowFrame.origin.y -= currentFrame.origin.y

      let screenMultiplier = CGSize(
        width: nextFrame.width / currentFrame.width,
        height: nextFrame.height / currentFrame.height
      )

      let width = windowFrame.size.width * screenMultiplier.width
      let height = windowFrame.size.height * screenMultiplier.height
      let x = nextFrame.origin.x + (windowFrame.origin.x * screenMultiplier.width)
      let y = nextFrame.origin.y  + (windowFrame.origin.y * screenMultiplier.height)
      var newFrame: CGRect = .init(x: x, y: y, width: width, height: height)
      newFrame = invert(newFrame)

      window.frame = newFrame
    }
  }

  private func getFocusedWindow() throws -> (WindowAccessibilityElement, CGRect) {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      throw WindowCommandRunnerError.unableToResolveFrontmostApplication
    }

    let window = try AppAccessibilityElement(frontmostApplication.processIdentifier)
      .focusedWindow()

    guard let windowFrame = window.frame else {
      throw WindowCommandRunnerError.unabelToResolveWindowFrame
    }

    return (window, windowFrame)
  }

  @MainActor
  private func interpolateWindowFrame(from oldFrame: CGRect, to newFrame: CGRect,
                                      curve: InterpolationCurve = .linear,
                                      duration: TimeInterval, onUpdate: @MainActor @escaping (CGRect) -> Void) {
    if duration == 0 {
      onUpdate(newFrame)
      return
    }

    self.task = Task {
      await withThrowingTaskGroup(of: Void.self) { group in
        let numberOfFrames = Int(duration * 120)
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
    return oldValue + (newValue - oldValue) * progress
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
    return screen.visibleFrame.origin.y
  }
}

func isDockHidden(_ screen: NSScreen) -> Bool {
  getDockSize(screen) < 25
}

func invert(_ rect: CGRect) -> CGRect {
  let inverted = CGPoint(x: rect.origin.x, y: NSScreen.maxY - rect.maxY)
  return CGRect(origin: inverted, size: rect.size)
}

extension NSScreen {
  var isMainDisplay: Bool { frame.origin == .zero }
  static var mainDisplay: NSScreen? { screens.first(where: { $0.isMainDisplay }) }

  static func screenContaining(_ rect: CGRect) -> NSScreen? {
    NSScreen.screens.first(where: { $0.frame.contains(rect) })
  }

  static var maxY: CGFloat {
    screens.max(by: {
      $0.frame.maxY < $1.frame.maxY
    })?.frame.maxY ?? 0
  }
}

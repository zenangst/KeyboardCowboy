import AXEssibility
import Cocoa
import Foundation

enum WindowCommandRunnerError: Error {
  case unableToResolveFrontmostApplication
  case unabelToResolveWindowFrame
}

final class WindowCommandRunner {
  private var fullscreenCache = [CGWindowID: CGRect]()

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

  private func center(_ screen: NSScreen? = NSScreen.main, animationDuration: Double) throws {
    guard let screen = screen else { return }

    let (window, windowFrame) = try getFocusedWindow()
    let dockSize = getDockSize(screen)
    let dockPosition = getDockPosition(screen)

    let menubarOffset = abs(screen.visibleFrame.size.height - screen.frame.size.height)
    let screenFrame = screen.frame
    var x: Double = screenFrame.midX - (windowFrame.width / 2)
    var y: Double = screenFrame.midY - (windowFrame.height / 2) + menubarOffset / 2

    switch dockPosition {
    case .bottom:
      y -= dockSize
    case .left:
      x += dockSize / 2
    case .right:
      x -= dockSize / 2
    }

    let newRect = CGRect(x: x, y: y, width: windowFrame.width, height: windowFrame.height)

    interpolateWindowFrame(from: windowFrame, to: newRect, duration: animationDuration, onUpdate: { newRect in
      window.frame?.origin = newRect.origin
    })
  }

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

    var animationDuration = animationDuration
    if let runningApplication = NSWorkspace.shared.frontmostApplication {
      // Disable animation for Xcode
      if runningApplication.bundleIdentifier?.lowercased().contains("xcode") == true {
        animationDuration = 0
      }
    }

    let dockSize = getDockSize(screen)
    if getDockPosition(screen) == .bottom { newValue.origin.y -= dockSize }
    let delta = ((window.frame?.size.width) ?? 0) - newValue.size.width
    let shouldToggle = delta >= -1 && delta <= 1
    if shouldToggle, let cachedFrame = fullscreenCache[window.id] {
      interpolateWindowFrame(from: windowFrame, to: cachedFrame, duration: animationDuration) { newRect in
        window.frame = newRect
      }
    } else {
      let statusBarHeight = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        .button?
        .window?
        .frame
        .height ?? 0
      newValue.origin.y -= statusBarHeight + NSStatusBar.system.thickness

      interpolateWindowFrame(from: windowFrame, to: newValue, duration: animationDuration) { newRect in
        window.frame = newRect
      }

      fullscreenCache[window.id] = windowFrame
    }
  }

  private func move(_ byValue: Int, in direction: WindowCommand.Direction,
                    constrainedToScreen: Bool,
                    animationDuration: Double) throws {
    guard let screen = NSScreen.main else { return }
    let newValue = CGFloat(byValue)
    let dockSize = getDockSize(screen)
    let dockPosition = getDockPosition(screen)
    var (window, windowFrame) = try getFocusedWindow()
    let oldWindowFrame = windowFrame

    switch direction {
    case .leading:
      windowFrame.origin.x -= newValue
    case .topLeading:
      windowFrame.origin.x -= newValue
      windowFrame.origin.y -= newValue
    case .top:
      windowFrame.origin.y -= newValue
    case .topTrailing:
      windowFrame.origin.x += newValue
      windowFrame.origin.y -= newValue
    case .trailing:
      windowFrame.origin.x += newValue
    case .bottomTrailing:
      windowFrame.origin.x += newValue
      windowFrame.origin.y += newValue
    case .bottom:
      windowFrame.origin.y += newValue
    case .bottomLeading:
      windowFrame.origin.y += newValue
      windowFrame.origin.x -= newValue
    }

    var dockRightSize: CGFloat = 0
    var dockBottomSize: CGFloat = 0
    var dockLeftSize: CGFloat = 0

    switch dockPosition {
    case .bottom:
      dockBottomSize = dockSize
    case .left:
      dockLeftSize = dockSize
    case .right:
      dockRightSize = dockSize
    }

    if let screen = NSScreen.screens.first(where: { $0.frame.contains(oldWindowFrame) }), constrainedToScreen {
      if windowFrame.maxX >= screen.frame.maxX - dockRightSize {
        windowFrame.origin.x = screen.frame.maxX - windowFrame.size.width - dockRightSize
      } else if windowFrame.origin.x <= dockLeftSize {
        windowFrame.origin.x = dockLeftSize
      } else if windowFrame.origin.x < screen.frame.origin.x {
        windowFrame.origin.x = screen.frame.origin.x
      }

      if windowFrame.maxY >= screen.frame.maxY - dockBottomSize {
        windowFrame.origin.y = screen.frame.maxY - windowFrame.size.height
        windowFrame.origin.y -= dockBottomSize
      } else if windowFrame.origin.y >= screen.visibleFrame.maxY {
        windowFrame.origin.y = screen.visibleFrame.maxY
      }
    }

    interpolateWindowFrame(from: oldWindowFrame, to: windowFrame, duration: animationDuration) { newRect in
      window.frame?.origin = newRect.origin
    }
  }

  private func increaseSize(_ byValue: Int, in direction: WindowCommand.Direction,
                            constrainedToScreen: Bool, animationDuration: Double) throws {
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
      newWindowFrame.origin.x = max(0, newWindowFrame.origin.x)
    }

    interpolateWindowFrame(from: oldWindowFrame, to: newWindowFrame, duration: animationDuration) { newRect in
      window.frame = newRect
    }
  }

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
      let newFrame: CGRect = .init(x: x, y: y, width: width, height: height)

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

  private func interpolateWindowFrame(from oldFrame: CGRect, to newFrame: CGRect, 
                                      duration: TimeInterval, onUpdate: @escaping (CGRect) -> Void) {
    if duration == 0 {
      onUpdate(newFrame)
      return
    }

    let numberOfFrames = Int(duration * 120)

    for frameIndex in 0...numberOfFrames {
      let progress = CGFloat(frameIndex) / CGFloat(numberOfFrames)
      let interpolatedOrigin = CGPoint(x: interpolate(from: oldFrame.origin.x, to: newFrame.origin.x, progress: progress),
                                       y: interpolate(from: oldFrame.origin.y, to: newFrame.origin.y, progress: progress))
      let interpolatedSize = CGSize(width: interpolate(from: oldFrame.size.width, to: newFrame.size.width, progress: progress),
                                    height: interpolate(from: oldFrame.size.height, to: newFrame.size.height, progress: progress))
      let interpolatedFrame = CGRect(origin: interpolatedOrigin, size: interpolatedSize)

      DispatchQueue.main.asyncAfter(deadline: .now() + (duration / TimeInterval(numberOfFrames)) * TimeInterval(frameIndex)) {
        onUpdate(interpolatedFrame)
      }
    }
  }

  private func interpolate(from oldValue: CGFloat, to newValue: CGFloat, progress: CGFloat) -> CGFloat {
    return oldValue + (newValue - oldValue) * progress
  }
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

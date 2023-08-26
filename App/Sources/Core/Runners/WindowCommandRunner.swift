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
      try decreaseSize(byValue, in: direction, constrainedToScreen: value)
    case .increaseSize(let byValue, let direction, let value):
      try increaseSize(byValue, in: direction, constrainedToScreen: value)
    case .move(let toValue, let direction, let value):
      try move(toValue, in: direction, constrainedToScreen: value)
    case .fullscreen(let padding):
      try fullscreen(with: padding)
    case .center:
      try center()
    case .moveToNextDisplay(let mode):
      try moveToNextDisplay(mode)
    }
  }

  // MARK: Private methods

  private func center(_ screen: NSScreen? = NSScreen.main) throws {
    guard let screen = screen else { return }

    let (window, windowFrame) = try getFocusedWindow()
    let screenFrame = screen.frame
    let x: Double = screenFrame.midX - (windowFrame.width / 2)
    let y: Double = (screenFrame.height / 2) - (windowFrame.height / 2)
    let origin: CGPoint = .init(x: x, y: y)

    window.frame?.origin = origin
  }

  private func fullscreen(with padding: Int) throws {
    guard let screen = NSScreen.main else { return }
    let (window, windowFrame) = try getFocusedWindow()

    let value: CGFloat
    if padding > 1 {
      value = CGFloat(padding / 2)
    } else {
      value = 0
    }

    let newValue = screen.visibleFrame.insetBy(dx: value, dy: value)

    if window.frame?.size.width == newValue.size.width,
       let cachedFrame = fullscreenCache[window.id] {
      window.frame = cachedFrame
    } else {
      window.frame = newValue
      fullscreenCache[window.id] = windowFrame
    }
  }

  private func move(_ byValue: Int, in direction: WindowCommand.Direction, 
                    constrainedToScreen: Bool) throws {
    let newValue = CGFloat(byValue)
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

    if let screen = NSScreen.screens.first(where: { $0.frame.contains(oldWindowFrame) }), constrainedToScreen {
      if windowFrame.maxX >= screen.frame.maxX {
        windowFrame.origin.x = screen.frame.maxX - windowFrame.size.width
      } else if windowFrame.origin.x <= 0 {
        windowFrame.origin.x = screen.frame.origin.x
      }

      if windowFrame.maxY >= screen.visibleFrame.maxY {
        windowFrame.origin.y = screen.visibleFrame.maxY - windowFrame.size.height
      } else if windowFrame.origin.y >= screen.visibleFrame.maxY {
        windowFrame.origin.y = screen.visibleFrame.maxY
      }
    }

    window.frame?.origin = windowFrame.origin
  }

  private func increaseSize(_ byValue: Int, in direction: WindowCommand.Direction,
                            constrainedToScreen: Bool) throws {
    let newValue = CGFloat(byValue)
    var (window, windowFrame) = try getFocusedWindow()

    switch direction {
    case .leading:
      windowFrame.origin.x -= newValue
      windowFrame.size.width += newValue
    case .topLeading:
      windowFrame.origin.x -= newValue
      windowFrame.size.width += newValue
      windowFrame.origin.y -= newValue
      windowFrame.size.height += newValue
    case .top:
      windowFrame.origin.y -= newValue
      windowFrame.size.height += newValue
    case .topTrailing:
      windowFrame.origin.y -= newValue
      windowFrame.size.height += newValue
      windowFrame.size.width += newValue
    case .trailing:
      windowFrame.size.width += newValue
    case .bottomTrailing:
      windowFrame.size.width += newValue
      windowFrame.size.height += newValue
    case .bottom:
      windowFrame.size.height += newValue
    case .bottomLeading:
      windowFrame.origin.x -= newValue
      windowFrame.size.width += newValue
      windowFrame.size.height += newValue
    }

    if constrainedToScreen {
      windowFrame.origin.x = max(0, windowFrame.origin.x)
    }

    window.frame = windowFrame
  }

  private func decreaseSize(_ byValue: Int, in direction: WindowCommand.Direction,
                            constrainedToScreen: Bool) throws {
    let newValue = CGFloat(byValue)
    var (window, windowFrame) = try getFocusedWindow()
    let oldValue = windowFrame

    switch direction {
    case .leading:
      windowFrame.origin.x += newValue
      windowFrame.size.width -= newValue
      window.frame = windowFrame

      if window.frame?.width != windowFrame.width {
        window.frame?.origin.x = oldValue.origin.x
      }
    case .topLeading:
      windowFrame.size.width -= newValue
      windowFrame.size.height -= newValue
      window.frame = windowFrame
    case .top:
      windowFrame.size.height -= newValue
      window.frame = windowFrame
    case .topTrailing:
      windowFrame.origin.y += newValue
      windowFrame.size.height -= newValue
      windowFrame.size.width -= newValue
      window.frame = windowFrame

      if window.frame?.width != windowFrame.width {
        window.frame?.origin = oldValue.origin
      }
    case .trailing:
      windowFrame.size.width -= newValue
      window.frame = windowFrame
    case .bottomTrailing:
      windowFrame.origin.y += newValue
      windowFrame.size.width -= newValue
      windowFrame.size.height -= newValue
      window.frame = windowFrame
    case .bottom:
      windowFrame.origin.y += newValue
      windowFrame.size.height -= newValue
      window.frame = windowFrame
    case .bottomLeading:
      windowFrame.origin.y += newValue
      windowFrame.origin.x += newValue
      windowFrame.size.width -= newValue
      windowFrame.size.height -= newValue
      window.frame = windowFrame

      if window.frame?.width != windowFrame.width {
        window.frame?.origin = oldValue.origin
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
      try self.center(nextScreen)
    case .relative:
      // MARK: ⚠️ This needs fixing

      let currentFrame = mainScreen.frame
      let nextFrame = nextScreen.frame

      let widthMultiplier = currentFrame.width / nextFrame.width
      let heightMultiplier = currentFrame.height / nextFrame.height

      let newX = (windowFrame.origin.x * widthMultiplier) + nextFrame.origin.x
      let newY = (windowFrame.origin.y * heightMultiplier) + nextFrame.origin.y

      window.frame?.origin = .init(x: newX, y: newY)
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
}

import AXEssibility
import Cocoa
import Combine
import Foundation
import Intercom
import MachPort

enum WindowCommandRunnerError: Error {
  case unableToResolveFrontmostApplication
  case unabelToResolveWindowFrame
}

@MainActor
final class WindowCommandRunner {
  private var lastKeyCode: Int64?
  private var shouldCycle: Bool = false
  private var isRepeatingEvent: Bool = false
  private var subscription: AnyCancellable?
  private var minSizeCache = [CGWindowID: CGSize]()
  private var centerCache = [CGWindowID: CGRect]()
  private var fullscreenCache = [CGWindowID: CGRect]()
  private var task: Task<Void, Error>? {
    willSet {
      task?.cancel()
    }
  }

  private lazy var systemElement = SystemAccessibilityElement()
  private lazy var intercom = Intercom(MouseDefIntercomApp.self)

  nonisolated init() {}

  func subscribe(to publisher: Published<MachPortEvent?>.Publisher) {
    subscription = publisher
      .compactMap { $0 }
      .sink { [weak self] machPortEvent in
        guard let self else { return }
        let isRepeatingEvent: Bool = machPortEvent.event.getIntegerValueField(.keyboardEventAutorepeat) == 1

        self.isRepeatingEvent = isRepeatingEvent
        self.shouldCycle = machPortEvent.keyCode == self.lastKeyCode
        self.lastKeyCode = machPortEvent.keyCode
    }
  }

  @MainActor
  func run(_ command: WindowCommand) async throws {
    guard let currentScreen = NSScreen.main,
          let mainDisplay = NSScreen.mainDisplay else { return }

    try getFocusedWindow(sizeCache: {
      switch command.kind {
      case .anchor: true
      default: false
      }
    }()) {
      app,
      activeWindow,
      originFrame in
      let newFrame: CGRect
      switch command.kind {
      case .anchor(let position, let padding):
        let minSize: CGSize?
        if let size = minSizeCache[activeWindow.id] {
          minSize = CGSize(width: size.width + CGFloat(padding),
                           height: size.height + CGFloat(padding))
        } else {
          minSize = nil
        }
        newFrame = WindowRunnerAnchorWindow.calculateRect(
          originFrame,
          minSize: minSize,
          shouldCycle: shouldCycle,
          position: position,
          padding: padding,
          currentScreen: currentScreen,
          mainDisplay: mainDisplay
        )
        
        interpolateWindowFrame(
          from: originFrame,
          to: newFrame,
          minSize: minSize,
          currentScreen: currentScreen,
          mainDisplay: mainDisplay,
          constrainedToScreen: true,
          duration: command.animationDuration,
          onUpdate: { activeWindow.frame = $0 }
        )
        return
      case .decreaseSize(let byValue, let direction, let constrainedToScreen):
        newFrame = WindowRunnerDecreaseWindowSize.calculateRect(
          originFrame,
          byValue: byValue,
          in: direction,
          constrainedToScreen: constrainedToScreen,
          currentScreen: currentScreen,
          mainDisplay: mainDisplay
        )
      case .increaseSize(let byValue, let direction, let padding, let constrainedToScreen):
        newFrame = WindowRunnerIncreaseWindowSize.calculateRect(
          originFrame,
          byValue: byValue,
          in: direction,
          padding: padding,
          constrainedToScreen: constrainedToScreen,
          currentScreen: currentScreen,
          mainDisplay: mainDisplay
        )
      case .move(let byValue, let direction, let padding, let constrainedToScreen):
        app.enhancedUserInterface = !isRepeatingEvent
        newFrame = WindowRunnerMoveWindow.calculateRect(
          originFrame,
          byValue: byValue,
          in: direction,
          padding: padding,
          constrainedToScreen: constrainedToScreen,
          currentScreen: currentScreen,
          mainDisplay: mainDisplay
        )
      case .fullscreen(let padding):
        if intercom.isRunning() {
          intercom.send(.snapToFullscreen, userInfo: ["padding": padding])
          return
        }

        let resolvedFrame = WindowRunnerFullscreen.calculateRect(
          originFrame,
          padding: padding,
          currentScreen: currentScreen,
          mainDisplay: mainDisplay)
        
        let lhs = resolvedFrame.origin.x + resolvedFrame.origin.y + resolvedFrame.width + resolvedFrame.size.height + statusBarHeight()
        let rhs = originFrame.origin.x + originFrame.origin.y + originFrame.width + originFrame.size.height
        let delta = abs(lhs - rhs)
        let limit = currentScreen.visibleFrame.height - currentScreen.frame.height - CGFloat(padding)
        // Compare the new and old width to decide whether to restore the previous frame
        // or set a new one. This resolves a problem where fullscreen mode fails when the
        // window is anchored to the right side of the screen.
        let widthDelta = originFrame.size.width - resolvedFrame.size.width

        if delta <= abs(limit),
           abs(widthDelta) <= delta,
           let restoreFrame = fullscreenCache[activeWindow.id] {
          newFrame = restoreFrame
        } else {
          newFrame = resolvedFrame
          fullscreenCache[activeWindow.id] = originFrame
        }
      case .center:
        let resolvedFrame = WindowRunnerCenterWindow.calculateRect(
          originFrame,
          currentScreen: currentScreen,
          mainDisplay: mainDisplay
        )

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
        try WindowMoveWindowToNextDisplay.run(activeWindow, kind: mode)
        return
      }

      interpolateWindowFrame(
        from: originFrame,
        to: newFrame,
        currentScreen: currentScreen,
        mainDisplay: mainDisplay,
        duration: command.animationDuration,
        onUpdate: { activeWindow.frame = $0 }
      )

      intercom.send(.autoHideDockIfNeeded)
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

  private func getFocusedWindow(sizeCache: Bool = false, then: (AppAccessibilityElement, WindowAccessibilityElement, CGRect) throws -> Void) throws {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      throw WindowCommandRunnerError.unableToResolveFrontmostApplication
    }

    let app = AppAccessibilityElement(frontmostApplication.processIdentifier)

    var previousValue: Bool = false
    if app.enhancedUserInterface == true {
      app.enhancedUserInterface = false
      previousValue = true
    }


    var focusedElement: AnyFocusedAccessibilityElement
    let focusedWindow: WindowAccessibilityElement?
    do {
      focusedElement = try systemElement.focusedUIElement(0.00275)
      if let focusedApp = focusedElement.app {
        focusedWindow = try focusedApp.focusedWindow()
      } else {
        focusedWindow = try app.focusedWindow()
      }
    } catch {
      let element = try app.focusedWindow()
      focusedElement = AnyFocusedAccessibilityElement(element.reference)
      focusedWindow = element
    }

    guard let focusedWindow, let windowFrame = focusedWindow.frame else {
      app.enhancedUserInterface = previousValue
      throw WindowCommandRunnerError.unabelToResolveWindowFrame
    }

    if sizeCache, minSizeCache[focusedWindow.id] == nil, let oldSize = focusedWindow.size {
      focusedWindow.frame?.size = .zero
      if let size = focusedWindow.size {
        minSizeCache[focusedWindow.id] = size
      }
      focusedWindow.frame?.size = oldSize
    }

    try then(app, focusedWindow, windowFrame)

    app.enhancedUserInterface = previousValue
  }

  @MainActor
  private func interpolateWindowFrame(from oldFrame: CGRect, to newFrame: CGRect,
                                      minSize: CGSize? = nil,
                                      currentScreen: NSScreen, mainDisplay: NSScreen,
                                      curve: InterpolationCurve = .easeInOut,
                                      constrainedToScreen: Bool = false, duration: TimeInterval,
                                      onUpdate: @MainActor @escaping @Sendable (CGRect) -> Void) {
    let dockSize = getDockSize(mainDisplay)
    let dockPosition = getDockPosition(mainDisplay)
    let currenScreenFrame = currentScreen.frame
    let currentScreenVisibleFrame = currentScreen.visibleFrame
    let currentScreenIsMainDisplay = currentScreen.isMainDisplay
    let mainDisplayMaxY = mainDisplay.frame.maxY
    let maximumFramesPerSecond = TimeInterval(currentScreen.maximumFramesPerSecond)

    let dockRightSize: CGFloat
    let dockBottomSize: CGFloat
    let dockLeftSize: CGFloat

    switch dockPosition {
    case .bottom:
      dockRightSize = 0
      dockLeftSize = 0
      dockBottomSize = dockSize
    case .left:
      dockBottomSize = 0
      dockLeftSize = dockSize
      dockRightSize = 0
    case .right:
      dockBottomSize = 0
      dockLeftSize = 0
      dockRightSize = dockSize
    }

    if duration == 0 {
      var modifiedFrame = newFrame
      if constrainedToScreen {
        Self.constrainToMax(
          &modifiedFrame,
          minSize: minSize,
          currenScreenFrame: currenScreenFrame,
          currenScreenVisibleFrame: currentScreenVisibleFrame,
          dockBottomSize: dockBottomSize,
          dockLeftSize: dockLeftSize,
          dockRightSize: dockRightSize,
          currentScreenIsMainDisplay: currentScreenIsMainDisplay,
          mainDisplayMaxY: mainDisplayMaxY
        )
      }
      onUpdate(modifiedFrame)
      return
    }

    self.task = Task {
      await withThrowingTaskGroup(of: Void.self) { group in
        let numberOfFrames = Int(duration * maximumFramesPerSecond)
        for frameIndex in 0...numberOfFrames {
          group.addTask {
            let progress = CGFloat(frameIndex) / CGFloat(numberOfFrames)
            let easedProgress: CGFloat

            switch curve {
            case .easeIn:
              easedProgress = await Self.easeIn(progress)
            case .easeInOut:
              easedProgress = await Self.easeInOut(progress)
            case .spring:
              easedProgress = await Self.spring(progress)
            case .linear:
              easedProgress = progress
            }

            let interpolatedOrigin = CGPoint(x: await Self.interpolate(from: oldFrame.origin.x, to: newFrame.origin.x, progress: easedProgress),
                                             y: await Self.interpolate(from: oldFrame.origin.y, to: newFrame.origin.y, progress: easedProgress))
            let interpolatedSize = CGSize(width: await Self.interpolate(from: oldFrame.size.width, to: newFrame.size.width, progress: easedProgress),
                                          height: await Self.interpolate(from: oldFrame.size.height, to: newFrame.size.height, progress: easedProgress))
            var interpolatedFrame = CGRect(origin: interpolatedOrigin, size: interpolatedSize)
            let delay = (duration / TimeInterval(numberOfFrames)) * TimeInterval(frameIndex)

            if constrainedToScreen {
              await Self.constrainToMax(
                &interpolatedFrame,
                minSize: minSize,
                currenScreenFrame: currenScreenFrame,
                currenScreenVisibleFrame: currentScreenVisibleFrame,
                dockBottomSize: dockBottomSize,
                dockLeftSize: dockLeftSize,
                dockRightSize: dockRightSize,
                currentScreenIsMainDisplay: currentScreenIsMainDisplay,
                mainDisplayMaxY: mainDisplayMaxY
              )
            }

            try await Task.sleep(for: .seconds(delay))
            try Task.checkCancellation()
            await onUpdate(interpolatedFrame)
          }
        }
      }
    }
  }

  private static func constrainToMax(_ interpolatedFrame: inout CGRect,
                                     minSize: CGSize? = nil,
                                     currenScreenFrame: CGRect,
                                     currenScreenVisibleFrame: CGRect,
                                     dockBottomSize: CGFloat,
                                     dockLeftSize: CGFloat,
                                     dockRightSize: CGFloat,
                                     currentScreenIsMainDisplay: Bool,
                                     mainDisplayMaxY: CGFloat) {
    let maxX = currenScreenFrame.maxX - (minSize?.width ?? interpolatedFrame.width)
    let maxY = currenScreenFrame.maxY - (minSize?.height ?? interpolatedFrame.height)

    interpolatedFrame.origin.x = min(interpolatedFrame.origin.x, maxX)

    if currentScreenIsMainDisplay {
      interpolatedFrame.origin.y = min(interpolatedFrame.origin.y, maxY - dockBottomSize)
    } else {
      let maxY = mainDisplayMaxY - currenScreenVisibleFrame.origin.y - interpolatedFrame.height
      interpolatedFrame.origin.y = min(interpolatedFrame.origin.y, maxY)
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

  static func screenIntersects(_ rect: CGRect) -> NSScreen? {
    NSScreen.screens.first(where: { $0.frame.intersects(rect) })
  }

  static var maxY: CGFloat {
    var maxY = 0.0 as CGFloat
    for screen in screens {
      maxY = CGFloat.maximum(screen.frame.maxY, maxY)
    }
    return maxY
  }
}

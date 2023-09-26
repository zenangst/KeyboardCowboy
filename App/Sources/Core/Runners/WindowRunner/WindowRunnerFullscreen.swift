import Cocoa

final class WindowRunnerFullscreen {
  private init() {}

  static func calulateRect(_ originFrame: CGRect,
                           currentScreen: NSScreen,
                           mainDisplay: NSScreen) -> CGRect {
    let dockSize = getDockSize(currentScreen)
    let dockPosition = getDockPosition(currentScreen)
    let x: CGFloat
    let y: CGFloat
    let size = CGSize(width: currentScreen.visibleFrame.width,
                      height: currentScreen.visibleFrame.height)
    let newFrame: CGRect

    if currentScreen == mainDisplay {
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
      y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
        fn.subtract(currentScreen.visibleFrame.origin.y)
        fn.subtract(size.height)
      }
      newFrame = CGRect(origin: CGPoint(x: x, y: y), size: size)
    }

    return newFrame
  }
}

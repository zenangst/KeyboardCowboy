import Cocoa

final class WindowRunnerFullscreen {
  private init() {}

  static func calculateRect(_ originFrame: CGRect,
                            padding: Int,
                            currentScreen: NSScreen,
                            mainDisplay: NSScreen) -> CGRect {
    let paddingOffset = CGFloat(padding)
    let dockSize = getDockSize(currentScreen)
    let dockPosition = getDockPosition(currentScreen)
    let x: CGFloat
    let y: CGFloat
    let size = CGSize(width: currentScreen.visibleFrame.width - paddingOffset * 2,
                      height: currentScreen.visibleFrame.height - paddingOffset * 2)
    let newFrame: CGRect

    if currentScreen == mainDisplay {
      x = CGFloat.formula(currentScreen.frame.origin.x) { fn in
        fn.add(paddingOffset)
      }
      y = CGFloat.formula(currentScreen.frame.origin.y) { fn in
        fn.add(currentScreen.frame.height)
        fn.subtract(size.height)
        fn.subtract({ dockPosition == .bottom ? dockSize : 0 }())
        fn.subtract(paddingOffset)
      }

      newFrame = CGRect(origin: CGPoint(x: x, y: y), size: size)
    } else {
      // Handle secondary screens
      x = CGFloat.formula(currentScreen.frame.origin.x) { fn in
        fn.add(paddingOffset / 2)
      }
      y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
        fn.subtract(currentScreen.visibleFrame.origin.y)
        fn.subtract(size.height)
        fn.subtract(paddingOffset)
      }
      newFrame = CGRect(origin: CGPoint(x: x, y: y), size: size)
    }

    return newFrame
  }
}

import Cocoa

final class WindowRunnerCenterWindow {
  private init() {}

  static func calulateRect(_ originFrame: CGRect,
                           currentScreen: NSScreen,
                           mainDisplay: NSScreen) -> CGRect {
    let dockSize = getDockSize(currentScreen)
    let dockPosition = getDockPosition(currentScreen)
    let x: CGFloat
    let y: CGFloat
    let newFrame: CGRect

    if currentScreen == mainDisplay {
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
    } else {
      // Handle secondary screens
      x = CGFloat.formula(currentScreen.frame.origin.x) { fn in
        fn.add(currentScreen.frame.width / 2)
        fn.subtract(originFrame.width / 2)
        fn.add({ dockPosition == .left ? dockSize / 2 : 0 }())
        fn.subtract({ dockPosition == .right ? dockSize / 2 : 0 }())
      }

      y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
        fn.subtract(currentScreen.visibleFrame.origin.y)
        fn.subtract(originFrame.height)
        fn.subtract({ (currentScreen.frame.size.height - originFrame.size.height) / 2 }())
        fn.add({ dockPosition == .bottom ? dockSize / 2 : 0 }())
      }

      newFrame = CGRect(origin: CGPoint(x: x, y: y), size: originFrame.size)
    }

    return newFrame
  }
}

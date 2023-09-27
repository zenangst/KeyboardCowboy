import Cocoa

final class WindowRunnerAnchorWindow {
  private init() {}

  static func calulateRect(_ originFrame: CGRect,
                           position: WindowCommand.Direction,
                           padding: Int,
                           currentScreen: NSScreen,
                           mainDisplay: NSScreen) -> CGRect {
    let paddingOffset = CGFloat(padding)
    let dockSize = getDockSize(currentScreen)
    let dockPosition = getDockPosition(currentScreen)

    let maxWidth = round(currentScreen.frame.width / 1.5) - paddingOffset * 1.5
    let midWidth = round(currentScreen.frame.width / 2) - paddingOffset * 1.5
    let minWidth = round(currentScreen.frame.width / 3) - paddingOffset * 1.5

    let maxHeight = round(currentScreen.frame.height / 1.5) - paddingOffset * 1.5
    let midHeight = round(currentScreen.frame.height / 2) - paddingOffset * 1.5
    let minHeight = round(currentScreen.frame.height / 3) - paddingOffset * 1.5

    let width: CGFloat
    let height: CGFloat
    let x: CGFloat
    let y: CGFloat

    let deltaLimit: CGFloat = 10

    switch position {
    case .topLeading:
      if abs(originFrame.width - maxWidth) < deltaLimit {
        width = midWidth
        height = midHeight
      } else if abs(originFrame.width - midWidth) < deltaLimit {
        width = minWidth
        height = minHeight
      } else {
        width = maxWidth
        height = maxHeight
      }

      x = currentScreen.frame.origin.x + paddingOffset

      if currentScreen == mainDisplay {
        y = CGFloat.formula(currentScreen.frame.origin.y) { fn in
          fn.add(currentScreen.frame.height)
          fn.subtract(height)
          fn.subtract({ dockPosition == .bottom ? dockSize : 0 }())
          fn.subtract(currentScreen.visibleFrame.height - height)
          fn.add(paddingOffset)
        }
      } else {
        y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
          fn.subtract(currentScreen.visibleFrame.origin.y)
          fn.subtract(height)
          fn.add(paddingOffset)
          fn.subtract(currentScreen.visibleFrame.height - height)
        }
      }
    case .top:
      width = currentScreen.frame.width - (paddingOffset * 2)
      if abs(originFrame.height - maxHeight) < deltaLimit {
        height = midHeight
      } else if abs(originFrame.height - midHeight) < deltaLimit {
        height = minHeight
      } else {
        height = maxHeight
      }

      x = CGFloat.formula(currentScreen.frame.origin.x) { fn in
        fn.add({ dockPosition == .left ? dockSize : 0 }())
        fn.add(paddingOffset)
      }

      if currentScreen == mainDisplay {
        y = CGFloat.formula(currentScreen.frame.origin.y) { fn in
          fn.add(currentScreen.frame.height)
          fn.subtract(height)
          fn.subtract({ dockPosition == .bottom ? dockSize : 0 }())
          fn.subtract(currentScreen.visibleFrame.height - height)
          fn.add(paddingOffset)
        }
      } else {
        y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
          fn.subtract(currentScreen.visibleFrame.origin.y)
          fn.subtract(height)
          fn.add(paddingOffset)
          fn.subtract(currentScreen.visibleFrame.height - height)
        }
      }
    case .topTrailing:
      if abs(originFrame.width - maxWidth) < deltaLimit {
        width = midWidth
        height = midHeight
      } else if abs(originFrame.width - midWidth) < deltaLimit {
        width = minWidth
        height = minHeight
      } else {
        width = maxWidth
        height = maxHeight
      }

      x = CGFloat.formula(currentScreen.frame.origin.x) { fn in
        fn.add(currentScreen.frame.size.width)
        fn.subtract(width)
        fn.subtract({ dockPosition == .right ? dockSize : 0 }())
        fn.subtract(paddingOffset)
      }
      if currentScreen == mainDisplay {
        y = CGFloat.formula(currentScreen.frame.origin.y) { fn in
          fn.add(currentScreen.frame.height)
          fn.subtract(height)
          fn.subtract({ dockPosition == .bottom ? dockSize : 0 }())
          fn.subtract(currentScreen.visibleFrame.height - height)
          fn.add(paddingOffset)
        }
      } else {
        y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
          fn.subtract(currentScreen.visibleFrame.origin.y)
          fn.subtract(height)
          fn.add(paddingOffset)
          fn.subtract(currentScreen.visibleFrame.height - height)
        }
      }
    case .leading:
      if abs(originFrame.width - maxWidth) < deltaLimit {
        width = midWidth
      } else if abs(originFrame.width - midWidth) < deltaLimit {
        width = minWidth
      } else {
        width = maxWidth
      }

      height = currentScreen.visibleFrame.height - (paddingOffset * 2)

      x = CGFloat.formula(currentScreen.frame.origin.x) { fn in
        fn.add({ dockPosition == .left ? dockSize : 0 }())
        fn.add(paddingOffset)
      }

      if currentScreen == mainDisplay {
        y = CGFloat.formula(currentScreen.frame.origin.y) { fn in
          fn.add(currentScreen.frame.height)
          fn.subtract(height)
          fn.subtract({ dockPosition == .bottom ? dockSize : 0 }())
          fn.subtract(paddingOffset)
        }
      } else {
        y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
          fn.subtract(currentScreen.visibleFrame.origin.y)
          fn.subtract(height)
          fn.subtract(paddingOffset)
        }
      }
    case .trailing:
      if abs(originFrame.width - maxWidth) < deltaLimit {
        width = midWidth
      } else if abs(originFrame.width - midWidth) < deltaLimit {
        width = minWidth
      } else {
        width = maxWidth
      }

      height = currentScreen.visibleFrame.height - (paddingOffset * 2)

      x = CGFloat.formula(currentScreen.frame.origin.x) { fn in
        fn.add(currentScreen.frame.size.width)
        fn.subtract(width)
        fn.subtract({ dockPosition == .right ? dockSize : 0 }())
        fn.subtract(paddingOffset)
      }

      if currentScreen == mainDisplay {
        y = CGFloat.formula(currentScreen.frame.origin.y) { fn in
          fn.add(currentScreen.frame.height)
          fn.subtract(height)
          fn.subtract({ dockPosition == .bottom ? dockSize : 0 }())
          fn.subtract(paddingOffset)
        }
      } else {
        y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
          fn.subtract(currentScreen.visibleFrame.origin.y)
          fn.subtract(height)
          fn.subtract(paddingOffset / 2)
        }
      }
    case .bottomLeading:
      if abs(originFrame.width - maxWidth) < deltaLimit {
        width = midWidth
        height = midHeight
      } else if abs(originFrame.width - midWidth) < deltaLimit {
        width = minWidth
        height = minHeight
      } else {
        width = maxWidth
        height = maxHeight
      }

      x = currentScreen.frame.origin.x + paddingOffset
      if currentScreen == mainDisplay {
        y = CGFloat.formula(currentScreen.frame.origin.y) { fn in
          fn.add(currentScreen.frame.height)
          fn.subtract(height)
          fn.subtract({ dockPosition == .bottom ? dockSize : 0 }())
          fn.subtract(paddingOffset)
        }
      } else {
        y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
          fn.subtract(currentScreen.visibleFrame.origin.y)
          fn.subtract(height)
          fn.subtract(paddingOffset)
        }
      }
    case .bottom:
      width = currentScreen.frame.width - (paddingOffset * 2)
      if abs(originFrame.height - maxHeight) < deltaLimit {
        height = midHeight
      } else if abs(originFrame.height - midHeight) < deltaLimit {
        height = minHeight
      } else {
        height = maxHeight
      }

      x = CGFloat.formula(currentScreen.frame.origin.x) { fn in
        fn.add({ dockPosition == .left ? dockSize : 0 }())
        fn.add(paddingOffset)
      }

      if currentScreen == mainDisplay {
        y = CGFloat.formula(currentScreen.frame.origin.y) { fn in
          fn.add(currentScreen.frame.height)
          fn.subtract(height)
          fn.subtract({ dockPosition == .bottom ? dockSize : 0 }())
          fn.subtract(paddingOffset / 2)
        }
      } else {
        y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
          fn.subtract(currentScreen.visibleFrame.origin.y)
          fn.subtract(height)
          fn.subtract(paddingOffset)
        }
      }
    case .bottomTrailing:
      if abs(originFrame.width - maxWidth) < deltaLimit {
        width = midWidth
        height = midHeight
      } else if abs(originFrame.width - midWidth) < deltaLimit {
        width = minWidth
        height = minHeight
      } else {
        width = maxWidth
        height = maxHeight
      }

      x = CGFloat.formula(currentScreen.frame.origin.x) { fn in
        fn.add(currentScreen.frame.size.width)
        fn.subtract(width)
        fn.subtract({ dockPosition == .right ? dockSize : 0 }())
        fn.subtract(paddingOffset)
      }

      if currentScreen == mainDisplay {
        y = CGFloat.formula(currentScreen.frame.origin.y) { fn in
          fn.add(currentScreen.frame.height)
          fn.subtract(height)
          fn.subtract({ dockPosition == .bottom ? dockSize : 0 }())
          fn.subtract(paddingOffset)
        }
      } else {
        y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
          fn.subtract(currentScreen.visibleFrame.origin.y)
          fn.subtract(height)
          fn.subtract(paddingOffset)
        }
      }
    }

    return CGRect(x: x, y: y, width: width, height: height)
  }
}
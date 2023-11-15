import Cocoa

enum WindowRunnerMoveWindow {
  static func calculateRect(_ originFrame: CGRect,
                            byValue: Int,
                            in direction: WindowCommand.Direction,
                            padding: Int,
                            constrainedToScreen: Bool,
                            currentScreen: NSScreen,
                            mainDisplay: NSScreen) -> CGRect {
    let padding = CGFloat(padding)
    let newValue = CGFloat(byValue)
    let dockSize = getDockSize(mainDisplay)
    let dockPosition = getDockPosition(mainDisplay)

    var newFrame = originFrame

    switch direction {
    case .leading:
      newFrame.origin.x -= newValue
    case .topLeading:
      newFrame.origin.x -= newValue
      newFrame.origin.y -= newValue
    case .top:
      newFrame.origin.y -= newValue
    case .topTrailing:
      newFrame.origin.x += newValue
      newFrame.origin.y -= newValue
    case .trailing:
      newFrame.origin.x += newValue
    case .bottomTrailing:
      newFrame.origin.x += newValue
      newFrame.origin.y += newValue
    case .bottom:
      newFrame.origin.y += newValue
    case .bottomLeading:
      newFrame.origin.y += newValue
      newFrame.origin.x -= newValue
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

    if constrainedToScreen {
      var maxX = currentScreen.frame.maxX - newFrame.width - dockRightSize
      var minX = max(currentScreen.frame.origin.x + dockLeftSize,
                     newFrame.origin.x)
      var maxY = currentScreen.isMainDisplay
      ? currentScreen.frame.maxY - newFrame.height  - dockBottomSize
      : mainDisplay.frame.maxY - currentScreen.visibleFrame.origin.y - originFrame.height
      var minY: CGFloat = newFrame.origin.y

      switch direction {
      case .leading, .trailing:
        maxX -= padding
        minX += padding
      case .topLeading, .bottomLeading:
        minX += padding
        maxY -= padding
      case .topTrailing, .bottomTrailing:
        maxX -= padding
        maxY -= padding
      case .top, .bottom:
        minY += padding
        maxY -= padding
      }

      newFrame.origin = CGPoint(x: min(minX, maxX), y: min(minY, maxY))
    }

    return newFrame
  }
}

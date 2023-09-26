import Cocoa

final class WindowRunnerMoveWindow {
  static func calulateRect(_ originFrame: CGRect,
                           byValue: Int,
                           in direction: WindowCommand.Direction,
                           constrainedToScreen: Bool,
                           currentScreen: NSScreen,
                           mainDisplay: NSScreen) -> CGRect {
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
      let maxX = currentScreen.frame.maxX - newFrame.width
      let maxY = currentScreen.frame.maxY - newFrame.height

      newFrame.origin.x = min(max(currentScreen.frame.origin.x + dockLeftSize,
                                        newFrame.origin.x), maxX - dockRightSize)

      if currentScreen.isMainDisplay {
        newFrame.origin.y = min(newFrame.origin.y, maxY - dockBottomSize)
      } else {
        let maxY = mainDisplay.frame.maxY - currentScreen.visibleFrame.origin.y - originFrame.height
        newFrame.origin.y = min(newFrame.origin.y, maxY)
      }
    }

    return newFrame
  }
}

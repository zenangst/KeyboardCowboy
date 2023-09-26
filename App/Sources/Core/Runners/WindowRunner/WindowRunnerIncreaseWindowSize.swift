import Cocoa

final class WindowRunnerIncreaseWindowSize {
  private init() {}

  static func calulateRect(_ originFrame: CGRect,
                           byValue: Int,
                           in direction: WindowCommand.Direction,
                           constrainedToScreen: Bool,
                           currentScreen: NSScreen,
                           mainDisplay: NSScreen) -> CGRect {
    let newValue = CGFloat(byValue)
    var newFrame = originFrame

    switch direction {
    case .leading:
      newFrame.origin.x -= newValue
      newFrame.size.width += newValue
    case .topLeading:
      newFrame.origin.x -= newValue
      newFrame.size.width += newValue
      newFrame.origin.y -= newValue
      newFrame.size.height += newValue
    case .top:
      newFrame.origin.y -= newValue
      newFrame.size.height += newValue
    case .topTrailing:
      newFrame.origin.y -= newValue
      newFrame.size.height += newValue
      newFrame.size.width += newValue
    case .trailing:
      newFrame.size.width += newValue
    case .bottomTrailing:
      newFrame.size.width += newValue
      newFrame.size.height += newValue
    case .bottom:
      newFrame.size.height += newValue
    case .bottomLeading:
      newFrame.origin.x -= newValue
      newFrame.size.width += newValue
      newFrame.size.height += newValue
    }

    if constrainedToScreen {
      newFrame.origin.x = max(currentScreen.frame.origin.x, newFrame.origin.x)
    }

    return newFrame
  }
}

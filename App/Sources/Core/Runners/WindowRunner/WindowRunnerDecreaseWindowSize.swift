import Cocoa

final class WindowRunnerDecreaseWindowSize {
  private init() {}

  static func calculateRect(_ originFrame: CGRect,
                            byValue: Int,
                            in direction: WindowCommand.Direction,
                            constrainedToScreen: Bool,
                            currentScreen: NSScreen,
                            mainDisplay: NSScreen) -> CGRect {
    let newValue = CGFloat(byValue)
    var newFrame = originFrame

    switch direction {
    case .leading:
      newFrame.origin.x += newValue
      newFrame.size.width -= newValue
    case .topLeading:
      newFrame.size.width -= newValue
      newFrame.size.height -= newValue
    case .top:
      newFrame.size.height -= newValue
    case .topTrailing:
      newFrame.origin.x += newValue
      newFrame.size.height -= newValue
      newFrame.size.width -= newValue
    case .trailing:
      newFrame.size.width -= newValue
    case .bottomTrailing:
      newFrame.origin.x += newValue
      newFrame.origin.y += newValue
      newFrame.size.width -= newValue
      newFrame.size.height -= newValue
    case .bottom:
      newFrame.origin.y += newValue
      newFrame.size.height -= newValue
    case .bottomLeading:
      newFrame.origin.y += newValue
      newFrame.size.width -= newValue
      newFrame.size.height -= newValue
    }
    return newFrame
  }
}

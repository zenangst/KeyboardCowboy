import Cocoa

enum WindowManagementIncreaseWindowSize {
  static func calculateRect(_ originFrame: CGRect,
                            byValue: Int,
                            in direction: WindowManagementCommand.Direction,
                            padding: Int,
                            constrainedToScreen: Bool,
                            currentScreen: NSScreen,
                            mainDisplay: NSScreen) -> CGRect {
    let padding = CGFloat(padding)
    let maxWidth = currentScreen.frame.width - padding * 2
    let maxHeight = currentScreen.frame.height - padding * 2
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

    newFrame.size.width = min(newFrame.width, maxWidth)
    newFrame.size.height = min(newFrame.height, maxHeight)

    if constrainedToScreen {
      let minX = max(currentScreen.frame.origin.x, padding)
      let maxX = min(newFrame.origin.x, currentScreen.frame.maxX + maxWidth)
      let exceedsMax = newFrame.maxX >= currentScreen.frame.maxX

      if exceedsMax {
        newFrame.origin.x -= padding
        newFrame.size.width = currentScreen.frame.width - originFrame.origin.x
      } else {
        newFrame.origin.x = max(maxX, minX)
      }

      newFrame.origin.y = max(newFrame.origin.y, padding)
    }

    return newFrame
  }
}

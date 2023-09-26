import Cocoa

final class WindowRunnerMoveToNextDisplayRelative {
  private init() {}

  static func calulateRect(_ originFrame: CGRect,
                           currentScreen: NSScreen,
                           mainDisplay: NSScreen) -> CGRect {
    guard NSScreen.screens.count > 1 else { return originFrame }

    var nextScreen: NSScreen? = NSScreen.screens.first
    var foundMain: Bool = false
    for screen in NSScreen.screens {
      if foundMain {
        nextScreen = screen
        break
      } else if currentScreen == nextScreen {
        foundMain = true
      }
    }

    guard let nextScreen else { return originFrame }

    var (x, y): (CGFloat, CGFloat)
    let newFrame: CGRect
    let widthRatio: CGFloat = nextScreen.frame.width / currentScreen.frame.width
    let heightRatio = nextScreen.frame.height / currentScreen.frame.height
    let size = CGSize(width: round(originFrame.width * widthRatio),
                      height: round(originFrame.height * heightRatio))

    let relativeX = originFrame.origin.x - currentScreen.frame.origin.x
    let percentageX = relativeX / (currentScreen.frame.width * widthRatio)
    let nextScreenMaxWidth = nextScreen.frame.width * widthRatio
    let newX = nextScreenMaxWidth * percentageX

    x = nextScreen.frame.origin.x + newX

    let zeroPoint = mainDisplay.frame.maxY - currentScreen.visibleFrame.origin.y - originFrame.height
    let currentPoint = originFrame.origin.y
    let diff = currentPoint - zeroPoint
    let transformedDiff = diff * heightRatio

    y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
      fn.subtract(nextScreen.frame.origin.y)
      fn.subtract(size.height)
      fn.add(transformedDiff)
    }

    let origin = CGPoint(x: x, y: y)
    newFrame = CGRect(origin: origin, size: size)

    return newFrame
  }
}

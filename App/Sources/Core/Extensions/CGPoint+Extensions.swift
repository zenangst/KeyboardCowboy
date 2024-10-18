import Cocoa

extension CGPoint {
  var mainDisplayFlipped: CGPoint {
    CGPoint(x: x, y: NSScreen.mainDisplay!.frame.maxY - y)
  }

  func delta(_ rhs: CGPoint) -> CGPoint {
    CGPoint(x: abs(x - rhs.x), y: abs(y - rhs.y))
  }
}

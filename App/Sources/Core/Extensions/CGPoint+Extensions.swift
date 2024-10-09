import Cocoa

extension CGPoint {
  var mainDisplayFlipped: CGPoint {
    CGPoint(x: x, y: NSScreen.mainDisplay!.frame.maxY - y)
  }
}

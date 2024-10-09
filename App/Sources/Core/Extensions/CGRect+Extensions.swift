import Cocoa

extension CGRect {
  var mainDisplayFlipped: CGRect {
    CGRect(
      origin: CGPoint(x: origin.x, y: NSScreen.mainDisplay!.frame.maxY - maxY),
      size: size
    )
  }
}

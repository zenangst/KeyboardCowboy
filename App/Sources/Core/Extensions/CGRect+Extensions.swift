import Cocoa

extension CGRect {
  var mainDisplayFlipped: CGRect {
    CGRect(
      origin: CGPoint(x: origin.x, y: NSScreen.mainDisplay!.frame.maxY - maxY),
      size: size
    )
  }

  func delta(_ rhs: CGRect) -> CGRect {
    CGRect(origin: origin.delta(rhs.mainDisplayFlipped.origin),
           size: size.delta(rhs.size))
  }
}

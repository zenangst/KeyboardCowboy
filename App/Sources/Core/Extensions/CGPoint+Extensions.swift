import Cocoa

extension CGPoint {
  var mainDisplayFlipped: CGPoint {
    CGPoint(x: x, y: NSScreen.mainDisplay!.frame.maxY - y)
  }

  func delta(_ rhs: CGPoint) -> CGPoint {
    CGPoint(x: abs(x - rhs.x), y: abs(y - rhs.y))
  }

  @MainActor static var debug: Bool = false

  @MainActor
  func hasDifference(greaterThan tolerance: CGFloat, comparedTo other: CGPoint) -> Bool {
    let xDiff = abs(self.x - round(other.x))
    let yDiff = abs(self.y - round(other.y))

    if Self.debug {
      if xDiff > tolerance {
        print("xDiff: \(xDiff) exceeds tolerance: \(tolerance)")
      }
      if yDiff > tolerance {
        print("yDiff: \(yDiff) exceeds tolerance: \(tolerance)")
      }
    }

    return xDiff > tolerance || yDiff > tolerance
  }
}

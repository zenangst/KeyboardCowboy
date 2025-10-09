import Cocoa
import Windows

extension CGRect {
  @MainActor static var debug: Bool = false

  var mainDisplayFlipped: CGRect {
    CGRect(
      origin: CGPoint(x: origin.x, y: NSScreen.mainDisplay!.frame.maxY - maxY),
      size: size,
    )
  }

  func delta(_ rhs: CGRect) -> CGRect {
    CGRect(origin: origin.delta(rhs.mainDisplayFlipped.origin),
           size: size.delta(rhs.size))
  }

  @MainActor
  func isValid(for tiling: WindowTiling, window: WindowModel, in visibleFrame: CGRect, spacing: CGFloat) -> Bool {
    guard let tilingRect = tiling.rect(in: visibleFrame, spacing: spacing) else {
      return false
    }

    let foundDiff = hasDifference(greaterThan: spacing, comparedTo: tilingRect)

    if Self.debug, foundDiff {
      print("xxxxxxxxxxxxxxxx (\(foundDiff))")
      print(window.ownerName, tiling)
      print("windowRect", self)
      print("tilingRect", tilingRect)
      print("spacing", spacing)
      print("xxxxxxxxxxxxxxxx (\(foundDiff))")
    }

    return !foundDiff
  }

  @MainActor
  func hasDifference(greaterThan tolerance: CGFloat, comparedTo other: CGRect) -> Bool {
    let originDiff = origin.hasDifference(greaterThan: tolerance, comparedTo: other.origin)
    let sizeDiff = size.hasDifference(greaterThan: tolerance, comparedTo: other.size)

    if Self.debug {
      if originDiff {
        print("Origin Difference Detected")
      }
      if sizeDiff {
        print("Size Difference Detected")
      }
    }

    return originDiff || sizeDiff
  }
}

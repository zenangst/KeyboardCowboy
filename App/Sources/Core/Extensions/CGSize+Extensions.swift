import Foundation

extension CGSize {
  func delta(_ rhs: CGSize) -> CGSize {
    CGSize(width: abs(width - rhs.width),
           height: abs(height - rhs.height))
  }

  func inThreshold(_ value: CGFloat) -> Bool {
    value >= width && value >= height
  }

  @MainActor static var debug: Bool = false
  @MainActor
  func hasDifference(greaterThan tolerance: CGFloat, comparedTo other: CGSize) -> Bool {
    let widthDiff = abs(width - round(other.width))
    let heightDiff = abs(height - round(other.height))

    if Self.debug {
      if widthDiff > tolerance {
        print("widthDiff: \(widthDiff) exceeds tolerance: \(tolerance)")
      }
      if heightDiff > tolerance {
        print("heightDiff: \(heightDiff) exceeds tolerance: \(tolerance)")
      }
    }

    return widthDiff > tolerance || heightDiff > tolerance
  }
}

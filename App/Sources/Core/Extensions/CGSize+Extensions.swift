import Foundation

extension CGSize {
  func delta(_ rhs: CGSize) -> CGSize {
    CGSize(width: abs(width - rhs.width),
           height: abs(height - rhs.height))
  }

  func inThreshold(_ value: CGFloat) -> Bool {
    value >= width && value >= height
  }
}

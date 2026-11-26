import CoreGraphics

public extension WindowManagement {
  enum Direction: Sendable {
    case topLeading, top, topTrailing, leading, trailing, bottomLeading, bottom, bottomTrailing

    var offset: CGPoint {
      switch self {
      case .topLeading: CGPoint(x: -1, y: -1)
      case .top: CGPoint(x: 0, y: -1)
      case .topTrailing: CGPoint(x: 1, y: -1)
      case .leading: CGPoint(x: -1, y: 0)
      case .trailing: CGPoint(x: 1, y: 0)
      case .bottomLeading: CGPoint(x: -1, y: 1)
      case .bottom: CGPoint(x: 0, y: 1)
      case .bottomTrailing: CGPoint(x: 1, y: 1)
      }
    }
  }
}

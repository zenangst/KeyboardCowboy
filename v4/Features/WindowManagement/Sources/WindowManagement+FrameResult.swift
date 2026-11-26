import CoreGraphics

public extension WindowManagement {
  struct FrameResult: Equatable, Sendable {
    public let original: CGRect
    public let requested: CGRect
    public let observed: CGRect
  }
}

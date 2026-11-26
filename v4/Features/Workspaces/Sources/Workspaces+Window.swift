import Foundation

public extension Workspaces {
  struct Window: Sendable {
    public let id: Int
    public let pid: Int32
    public let ownerName: String
    public let size: CGSize
    public let alpha: Double

    public init(id: Int, pid: Int32, ownerName: String, size: CGSize, alpha: Double) {
      self.id = id
      self.pid = pid
      self.ownerName = ownerName
      self.size = size
      self.alpha = alpha
    }
  }
}

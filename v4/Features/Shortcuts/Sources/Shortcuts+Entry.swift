import Foundation

public extension Shortcuts {
  struct Entry: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
  }
}

import Foundation

public struct BuiltInCommand: Identifiable, Codable, Hashable {
  public let id: String
  public var name: String {
    switch kind {
    case .quickRun:
      return "Open Quick Run"
    }
  }
  public let kind: Kind

  public enum Kind: String, Codable, Hashable, CaseIterable, Identifiable {
    public var id: String { return self.rawValue }
    case quickRun

    public var displayValue: String {
      switch self {
      case .quickRun:
        return "Open Quick Run dialog"
      }
    }
  }

  public init(id: String = UUID().uuidString,
              kind: Kind) {
    self.id = id
    self.kind = kind
  }
}

import Foundation

public struct BuiltInCommand: Identifiable, Codable, Hashable {
  public let id: String
  public var name: String {
    switch kind {
    case .quickRun:
      return "Open Quick Run"
    case .repeatLastKeystroke:
      return "Repeat last keystroke"
    case .recordSequence:
      return "Record sequence"
    }
  }
  public let kind: Kind

  public enum Kind: String, Codable, Hashable, CaseIterable, Identifiable {
    public var id: String { return self.rawValue }
    case quickRun
    case repeatLastKeystroke
    case recordSequence

    public var displayValue: String {
      switch self {
      case .quickRun:
        return "Open Quick Run dialog"
      case .repeatLastKeystroke:
        return "Repeat last keystroke"
      case .recordSequence:
        return "Record sequence"
      }
    }
  }

  public init(id: String = UUID().uuidString,
              kind: Kind) {
    self.id = id
    self.kind = kind
  }
}

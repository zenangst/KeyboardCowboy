import Foundation

public struct BuiltInCommand: Identifiable, Codable, Hashable, Sendable {
  public var id: String
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

  public enum Kind: String, Codable, Hashable, CaseIterable, Identifiable, Sendable {
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

  public var isEnabled: Bool = true
  public var notification: Bool

  enum CodingKeys: String, CodingKey {
    case id, kind
    case isEnabled = "enabled"
    case notification
  }

  public init(id: String = UUID().uuidString,
              kind: Kind, notification: Bool) {
    self.id = id
    self.kind = kind
    self.notification = notification
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.kind = try container.decode(Kind.self, forKey: .kind)
    self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    self.notification = try container.decodeIfPresent(Bool.self, forKey: .notification) ?? false
  }
}

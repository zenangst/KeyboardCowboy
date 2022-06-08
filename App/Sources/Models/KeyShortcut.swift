import Foundation

/// Keyboard shortcut is a data-structure that directly
/// translates into a keyboard shortcut. This is
/// used to match if a certain `Workflow` is eligiable
/// to be invoked.
public struct KeyShortcut: Identifiable, Equatable, Codable, Hashable, Sendable {
  public let id: String
  public let key: String
  public let modifiers: [ModifierKey]?

  public var modifersDisplayValue: String {
    let modifiers = self.modifiers?.compactMap({ $0.pretty }) ?? []
    return modifiers.joined()
  }

  enum CodingKeys: String, CodingKey {
    case id
    case key
    case modifiers
  }

  public var stringValue: String {
    var input: String = (modifiers ?? [])
      .sorted(by: { $0.rawValue > $1.rawValue })
      .compactMap({ $0.rawValue.lowercased() }).joined()
    input.append(key)
    return input
  }

  public init(id: String = UUID().uuidString,
              key: String,
              modifiers: [ModifierKey]? = nil) {
    self.id = id
    self.key = key
    self.modifiers = modifiers
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.key = try container.decode(String.self, forKey: .key)
    self.modifiers = try? container.decodeIfPresent([ModifierKey].self, forKey: .modifiers)
  }
}

public extension KeyShortcut {
  static func empty(id: String = UUID().uuidString) -> KeyShortcut {
    KeyShortcut(id: id, key: "")
  }
}

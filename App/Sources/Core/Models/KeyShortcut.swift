import Foundation

/// Keyboard shortcut is a data-structure that directly
/// translates into a keyboard shortcut. This is
/// used to match if a certain `Workflow` is eligiable
/// to be invoked.
public struct KeyShortcut: Identifiable, Equatable, Codable, Hashable, Sendable {
  public let id: String
  public let key: String
  public let lhs: Bool
  public let modifiers: [ModifierKey]

  public var modifersDisplayValue: String {
    let modifiers = self.modifiers.map(\.pretty)
    return modifiers.joined()
  }

  enum CodingKeys: String, CodingKey {
    case id
    case key
    case modifiers
    case lhs
  }

  public var validationValue: String {
    return "\(modifersDisplayValue)\(key)"
  }

  public var stringValue: String {
    var input: String = modifiers
      .sorted(by: { $0.rawValue > $1.rawValue })
      .compactMap({ $0.rawValue.lowercased() }).joined()
    input.append(key)
    return input
  }

  public init(id: String = UUID().uuidString,
              key: String,
              lhs: Bool = true,
              modifiers: [ModifierKey] = []) {
    self.id = id
    self.key = key
    self.lhs = lhs
    self.modifiers = modifiers
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.key = try container.decode(String.self, forKey: .key)
    self.lhs = try container.decodeIfPresent(Bool.self, forKey: .lhs) ?? true

    var modifiers = (try? container.decodeIfPresent([ModifierKey].self, forKey: .modifiers)) ?? []
    modifiers.sort(by: { lhs, rhs in
      lhs.sortValue < rhs.sortValue
    })
    self.modifiers = modifiers
  }

  func copy() -> Self {
    KeyShortcut(key: key, lhs: lhs, modifiers: modifiers)
  }
}

public extension KeyShortcut {
  static func empty(id: String = UUID().uuidString) -> KeyShortcut {
    KeyShortcut(id: id, key: "", lhs: true)
  }
}

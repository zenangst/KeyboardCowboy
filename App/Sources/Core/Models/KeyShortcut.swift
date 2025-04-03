import Foundation
import SwiftUI

/// Keyboard shortcut is a data-structure that directly
/// translates into a keyboard shortcut. This is
/// used to match if a certain `Workflow` is eligiable
/// to be invoked.
struct KeyShortcut: Identifiable, Equatable, Codable, Hashable, Sendable, Transferable {
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .keyboardShortcut)
  }

  let id: String
  let key: String
  let modifiers: [ModifierKey]

  enum CodingKeys: String, CodingKey {
    case id
    case key
    case modifiers
  }

  enum MigrationKeys: String, CodingKey {
    case lhs
    case modifiers
  }

  init(id: String = UUID().uuidString, key: String, modifiers: [ModifierKey] = []) {
    self.id = id
    self.key = key
    self.modifiers = modifiers
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let migration = try decoder.container(keyedBy: MigrationKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.key = try container.decode(String.self, forKey: .key)
    self.modifiers = try container.decodeIfPresent([ModifierKey].self, forKey: .modifiers) ?? []
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.id, forKey: .id)
    try container.encode(self.key, forKey: .key)
    if !self.modifiers.isEmpty {
      try container.encode(self.modifiers, forKey: .modifiers)
    }
  }

  func copy() -> Self {
    KeyShortcut(key: key, modifiers: modifiers)
  }

  static func empty(id: String = UUID().uuidString) -> KeyShortcut {
    KeyShortcut(id: id, key: "")
  }

  static let anyKeyCode: Int = 3000
  static let anyKey: KeyShortcut = KeyShortcut(id: UUID().uuidString, key: "any")

  // MARK: Computed properties

  var modifersDisplayValue: String {
    let modifiers = self.modifiers.map(\.pretty)
    return modifiers.joined()
  }

  var validationValue: String {
    return "\(modifersDisplayValue)\(key)"
  }

  var stringValue: String {
    var input: String = modifiers
      .sorted(by: { $0.rawValue > $1.rawValue })
      .compactMap({ $0.rawValue.lowercased() }).joined()
    input.append(key)
    return input
  }
}

extension KeyShortcut {
  var cgFlags: CGEventFlags {
    var flags = CGEventFlags.maskNonCoalesced
    modifiers.forEach { flags.insert($0.cgEventFlags) }
    return flags
  }
}

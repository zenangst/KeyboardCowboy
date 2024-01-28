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
  let lhs: Bool
  let modifiers: [ModifierKey]

  var modifersDisplayValue: String {
    let modifiers = self.modifiers.map(\.pretty)
    return modifiers.joined()
  }

  enum CodingKeys: String, CodingKey {
    case id
    case key
    case modifiers
    case lhs
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

  init(id: String = UUID().uuidString,
              key: String,
              lhs: Bool = true,
              modifiers: [ModifierKey] = []) {
    self.id = id
    self.key = key
    self.lhs = lhs
    self.modifiers = modifiers
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.key = try container.decode(String.self, forKey: .key)
    self.lhs = try container.decodeIfPresent(Bool.self, forKey: .lhs) ?? true
    self.modifiers = (try? container.decodeIfPresent([ModifierKey].self, forKey: .modifiers)) ?? []
  }

  func copy() -> Self {
    KeyShortcut(key: key, lhs: lhs, modifiers: modifiers)
  }

  static func empty(id: String = UUID().uuidString) -> KeyShortcut {
    KeyShortcut(id: id, key: "", lhs: true)
  }
}

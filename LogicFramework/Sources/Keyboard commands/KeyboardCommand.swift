import Foundation

/// Keyboard commands only have output because the trigger
/// will be the `Combination` found in the `Workflow`.
public struct KeyboardCommand: Codable, Hashable {
  public let id: String
  public let keyboardShortcut: KeyboardShortcut

  public init(id: String = UUID().uuidString, keyboardShortcut: KeyboardShortcut) {
    self.id = id
    self.keyboardShortcut = keyboardShortcut
  }

  enum CodingKeys: String, CodingKey {
    case id
    case keyboardShortcut
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.keyboardShortcut = try container.decode(KeyboardShortcut.self, forKey: .keyboardShortcut)
  }
}

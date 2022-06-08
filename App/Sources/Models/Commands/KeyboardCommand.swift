import Foundation

/// Keyboard commands only have output because the trigger
/// will be the `Combination` found in the `Workflow`.
public struct KeyboardCommand: Identifiable, Codable, Hashable, Sendable {
  public let id: String
  public var name: String
  public let keyboardShortcut: KeyShortcut
  public var isEnabled: Bool = true

  public init(id: String = UUID().uuidString,
              name: String = "",
              keyboardShortcut: KeyShortcut) {
    self.id = id
    self.name = name
    self.keyboardShortcut = keyboardShortcut
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case keyboardShortcut
    case isEnabled = "enabled"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    self.keyboardShortcut = try container.decode(KeyShortcut.self, forKey: .keyboardShortcut)
    self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
  }
}

public extension KeyboardCommand {
  static func empty() -> KeyboardCommand {
    KeyboardCommand(keyboardShortcut: KeyShortcut(key: ""))
  }
}
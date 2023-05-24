import Foundation

/// Keyboard commands only have output because the trigger
/// will be the `Combination` found in the `Workflow`.
public struct KeyboardCommand: Identifiable, Codable, Hashable, Sendable {
  public var id: String
  public var name: String
  public let keyboardShortcuts: [KeyShortcut]
  @available(macOS, deprecated, message: "Use `.keyboardShortcuts`")
  public var keyboardShortcut: KeyShortcut {
    keyboardShortcuts.first!
  }
  public var isEnabled: Bool = true
  public var notification: Bool

  public init(id: String = UUID().uuidString,
              name: String = "",
              keyboardShortcut: KeyShortcut,
              notification: Bool = false) {
    self.id = id
    self.name = name
    self.keyboardShortcuts = [keyboardShortcut]
    self.notification = notification
  }

  public init(id: String = UUID().uuidString,
              name: String = "",
              keyboardShortcuts: [KeyShortcut],
              notification: Bool) {
    self.id = id
    self.name = name
    self.keyboardShortcuts = keyboardShortcuts
    self.notification = notification
  }

  enum MigrationKeys: String, CodingKey {
    case keyboardShortcut
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case keyboardShortcuts
    case isEnabled = "enabled"
    case notification
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let migrationContainer = try decoder.container(keyedBy: MigrationKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""

    if let keyboardShortcut = try? migrationContainer.decode(KeyShortcut.self, forKey: .keyboardShortcut) {
      self.keyboardShortcuts = [keyboardShortcut]
    } else {
      self.keyboardShortcuts = try container.decode([KeyShortcut].self, forKey: .keyboardShortcuts)
    }

    self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    self.notification = try container.decodeIfPresent(Bool.self, forKey: .notification) ?? false
  }
}

public extension KeyboardCommand {
  static func empty() -> KeyboardCommand {
    KeyboardCommand(keyboardShortcut: KeyShortcut(key: "", lhs: true), notification: false)
  }
}

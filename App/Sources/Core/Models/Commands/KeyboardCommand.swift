import Foundation

/// Keyboard commands only have output because the trigger
/// will be the `Combination` found in the `Workflow`.
struct KeyboardCommand: MetaDataProviding {
  let keyboardShortcuts: [KeyShortcut]
  var meta: Command.MetaData

  init(id: String = UUID().uuidString,
              name: String = "",
              keyboardShortcut: KeyShortcut,
              notification: Bool = false) {
    self.keyboardShortcuts = [keyboardShortcut]
    self.meta = Command.MetaData(id: id, name: name,
                                 isEnabled: true,
                                 notification: notification)
  }

  init(id: String = UUID().uuidString,
              name: String = "",
              keyboardShortcuts: [KeyShortcut],
              notification: Bool) {
    self.keyboardShortcuts = keyboardShortcuts
    self.meta = Command.MetaData(id: id, name: name,
                                 isEnabled: true,
                                 notification: notification)
  }

  enum MigrationCodingKeys: String, CodingKey {
    case id
    case name
    case keyboardShortcuts
    case isEnabled = "enabled"
    case notification
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }

    self.keyboardShortcuts = try container.decode([KeyShortcut].self, forKey: .keyboardShortcuts)
  }

  func copy() -> KeyboardCommand {
    KeyboardCommand(id: UUID().uuidString,
                    name: meta.name,
                    keyboardShortcuts: keyboardShortcuts.copy(),
                    notification: meta.notification)
  }
}

extension Collection where Element == KeyShortcut {
  func copy() -> [KeyShortcut] {
    map { $0.copy() }
  }
}

extension KeyboardCommand {
  static func empty() -> KeyboardCommand {
    KeyboardCommand(keyboardShortcut: KeyShortcut(key: "", lhs: true), notification: false)
  }
}

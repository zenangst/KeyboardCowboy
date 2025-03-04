import Foundation

/// Keyboard commands only have output because the trigger
/// will be the `Combination` found in the `Workflow`.
struct KeyboardCommand: MetaDataProviding {
  enum Kind: Codable, Hashable {
    case key(command: KeyCommand)
    case inputSource(command: InputSourceCommand)
  }

  struct KeyCommand: Codable, Hashable {
    var keyboardShortcuts: [KeyShortcut]
    var iterations: Int

    init(keyboardShortcuts: [KeyShortcut], iterations: Int) {
      self.keyboardShortcuts = keyboardShortcuts
      self.iterations = iterations
    }
  }

  struct InputSourceCommand: Codable, Hashable { }

  var meta: Command.MetaData
  let kind: Kind

  init(id: String = UUID().uuidString,
       name: String,
       kind: Kind,
       notification: Command.Notification? = nil,
       meta: Command.MetaData? = nil) {
    self.meta = meta ?? Command.MetaData(id: id, name: name,
                                         isEnabled: true,
                                         notification: notification)
    self.kind = kind
  }

  enum MigrationCodingKeys: String, CodingKey {
    case id
    case name
    case keyboardShortcuts
    case kind
    case isEnabled = "enabled"
    case iterations
    case notification
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }

    let migration = try decoder.container(keyedBy: MigrationCodingKeys.self)
    if let keyboardShortcuts = try migration.decodeIfPresent([KeyShortcut].self, forKey: .keyboardShortcuts) {
      let iterations = (try? migration.decodeIfPresent(Int.self, forKey: .iterations)) ?? 1
      self.kind = .key(command: .init(keyboardShortcuts: keyboardShortcuts, iterations: iterations))
    } else {
      self.kind = try container.decode(Kind.self, forKey: .kind)
    }
  }

  func copy() -> KeyboardCommand {
    KeyboardCommand(
      id: UUID().uuidString,
      name: self.name,
      kind: kind,
      notification: self.notification,
      meta: self.meta.copy()
    )
  }
}

extension Collection where Element == KeyShortcut {
  func copy() -> [KeyShortcut] {
    map { $0.copy() }
  }
}

extension KeyboardCommand {
  static func empty() -> KeyboardCommand {
    KeyboardCommand(
      name: "",
      kind: .key(command: .init(keyboardShortcuts: [KeyShortcut(key: "")], iterations: 1)),
      notification: nil
    )
  }
}

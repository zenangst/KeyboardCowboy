import Foundation

/// Keyboard commands only have output because the trigger
/// will be the `Combination` found in the `Workflow`.
struct KeyboardCommand: MetaDataProviding {
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
    meta = try container.decode(Command.MetaData.self, forKey: .meta)
    let migration = try decoder.container(keyedBy: MigrationCodingKeys.self)
    if let keyboardShortcuts = try migration.decodeIfPresent([KeyShortcut].self, forKey: .keyboardShortcuts) {
      let iterations = (try? migration.decodeIfPresent(Int.self, forKey: .iterations)) ?? 1
      kind = .key(command: .init(keyboardShortcuts: keyboardShortcuts, iterations: iterations))
      Task { await MainActor.run { Migration.shouldSave = true } }
    } else {
      kind = try container.decode(Kind.self, forKey: .kind)
    }
  }

  func copy() -> KeyboardCommand {
    KeyboardCommand(
      id: UUID().uuidString,
      name: name,
      kind: kind,
      notification: notification,
      meta: meta.copy(),
    )
  }
}

extension Collection<KeyShortcut> {
  func copy() -> [KeyShortcut] {
    map { $0.copy() }
  }
}

extension KeyboardCommand {
  static func empty() -> KeyboardCommand {
    KeyboardCommand(
      name: "",
      kind: .key(command: .init(keyboardShortcuts: [KeyShortcut(key: "")], iterations: 1)),
      notification: nil,
    )
  }
}

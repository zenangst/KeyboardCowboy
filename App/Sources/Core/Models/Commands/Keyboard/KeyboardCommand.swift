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

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    self.kind = try container.decode(Kind.self, forKey: .kind)
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

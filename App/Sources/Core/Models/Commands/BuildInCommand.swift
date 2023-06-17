import Foundation

struct BuiltInCommand: MetaDataProviding {
  var meta: Command.MetaData
  
  var name: String {
    switch kind {
    case .quickRun:
      return "Open Quick Run"
    case .repeatLastKeystroke:
      return "Repeat last keystroke"
    case .recordSequence:
      return "Record sequence"
    }
  }
  let kind: Kind

  enum Kind: String, Codable, Hashable, CaseIterable, Identifiable, Sendable {
    public var id: String { return self.rawValue }
    case quickRun
    case repeatLastKeystroke
    case recordSequence

    public var displayValue: String {
      switch self {
      case .quickRun:
        return "Open Quick Run dialog"
      case .repeatLastKeystroke:
        return "Repeat last keystroke"
      case .recordSequence:
        return "Record sequence"
      }
    }
  }

  enum MigrationCodingKeys: String, CodingKey {
    case id, kind
    case isEnabled = "enabled"
    case notification
  }

  init(id: String = UUID().uuidString,
              kind: Kind, notification: Bool) {
    self.kind = kind
    self.meta = .init(id: id, name: kind.displayValue, isEnabled: true, notification: notification)
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }
    self.kind = try container.decode(BuiltInCommand.Kind.self, forKey: .kind)
  }
}

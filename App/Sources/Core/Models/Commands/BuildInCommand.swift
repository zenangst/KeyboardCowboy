import Foundation

struct BuiltInCommand: MetaDataProviding {
  var meta: Command.MetaData
  let kind: Kind

  enum Kind: Codable, Hashable, Identifiable, Sendable {
    enum Action: String, Codable, Hashable, Sendable {
      case enable
      case disable
      case toggle
    }

    case macro(MacroAction)
    case userMode(UserMode, Action)
    case commandLine(CommandLineAction)

    var id: String {
      switch self {
        case .macro(let macro): macro.id
      case .userMode(let id, let action):
        switch action {
          case .enable: "enable-\(id)"
          case .disable: "disable-\(id)"
          case .toggle: "toggle-\(id)"
        }
      case .commandLine(let action): "commandLine-\(action.id)"
      }
    }

    var userModeId: UserMode.ID {
      switch self {
      case .macro(let action): action.id
      case .userMode(let model, _): model.id
      case .commandLine(let action): action.id
      }
    }

    public var displayValue: String {
      switch self {
        case .macro(let action):
          switch action.kind {
            case .remove: "Remove Macro"
            case .record: "Record Macro"
          }
        case .userMode(_, let action):
          switch action {
            case .enable: "Enable User Mode"
            case .disable: "Disable User Mode"
            case .toggle: "Toggle User Mode"
          }
      case .commandLine:
        "Open Command Line"
      }
    }
  }

  enum MigrationCodingKeys: String, CodingKey {
    case id, kind
    case isEnabled = "enabled"
    case notification
  }

  init(id: String = UUID().uuidString, kind: Kind, notification: Command.Notification?) {
    self.kind = kind
    self.meta = .init(id: id, name: kind.displayValue, isEnabled: true, notification: notification)
  }

  init(kind: Kind, meta: Command.MetaData) {
    self.kind = kind
    self.meta = meta
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

  func copy() -> BuiltInCommand {
    BuiltInCommand(kind: self.kind, meta: self.meta.copy())
  }
}

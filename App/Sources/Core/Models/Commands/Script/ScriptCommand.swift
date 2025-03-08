import Foundation

struct ScriptCommand: MetaDataProviding {
  enum MigrationKind: String, Codable {
    case appleScript = "scpt"
    case shellScript = "sh"
  }

  var kind: Kind
  var source: Source
  var meta: Command.MetaData

  init(id: String = UUID().uuidString,
       name: String, kind: Kind, source: Source,
       isEnabled: Bool = true,
       notification: Command.Notification? = nil,
       variableName: String? = nil) {
    self.kind = kind
    self.source = source
    self.meta = Command.MetaData(
      id: id, name: name, isEnabled: true, 
      notification: notification, variableName: variableName)
  }

  init(kind: Kind, source: Source, meta: Command.MetaData) {
    self.kind = kind
    self.source = source
    self.meta = meta
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    do {
      self.kind = try container.decode(Kind.self, forKey: .kind)
    } catch {
      let result = try container.decode(MigrationKind.self, forKey: .kind)
      switch result {
      case .appleScript:
        self.kind = .appleScript(variant: .regular)
      case .shellScript:
        self.kind = .shellScript
      }
    }
    self.source = try container.decode(Source.self, forKey: .source)
    self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
  }

  func copy() -> ScriptCommand {
    ScriptCommand(kind: self.kind, source: self.source, meta: self.meta.copy())
  }
}

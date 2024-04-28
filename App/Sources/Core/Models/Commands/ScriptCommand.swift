import Foundation

struct ScriptCommand: MetaDataProviding {
  enum Kind: String, Codable, Sendable {
    case appleScript = "scpt"
    case shellScript = "sh"
  }

  enum Source: Hashable, Codable, Sendable, Equatable {
    case path(String)
    case inline(String)

    var contents: String {
      switch self {
      case .path(let contents): contents
      case .inline(let contents): contents
      }
    }
  }

  var kind: Kind
  var source: Source
  var meta: Command.MetaData

  init(id: String = UUID().uuidString,
       name: String, kind: Kind, source: Source,
       isEnabled: Bool = true, notification: Bool,
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
      self.source = try container.decode(Source.self, forKey: .source)
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      let oldScript = try OldScriptCommand(from: decoder)

      let id: String
      let name: String
      let isEnabled: Bool

      switch oldScript {
      case .appleScript(let _id, let _isEnabled, let _name, _):
        self.kind = .appleScript
        id = _id
        name = _name ?? ""
        isEnabled = _isEnabled
      case .shell(let _id, let _isEnabled, let _name, _):
        self.kind = .shellScript
        id = _id
        name = _name ?? ""
        isEnabled = _isEnabled
      }

      switch oldScript.sourceType {
      case .path(let path):
        self.source = .path(path)
      case .inline(let source):
        self.source = .inline(source)
      }

      self.meta = Command.MetaData(id: id, name: name, isEnabled: isEnabled, notification: false)
    }
  }

  func copy() -> ScriptCommand {
    ScriptCommand(kind: self.kind, source: self.source, meta: self.meta.copy())
  }
}

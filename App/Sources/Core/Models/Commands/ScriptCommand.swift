import Foundation

struct ScriptCommand: MetaDataProviding {
  enum Kind: String, Codable, Sendable {
    case appleScript = "scpt"
    case shellScript = "sh"
  }

  enum Source: String, Codable, Sendable {
    case path
    case inline
  }

  var kind: Kind
  var source: Source
  var meta: Command.MetaData

  init(id: String = UUID().uuidString,
       name: String, kind: Kind, source: Source,
       isEnabled: Bool = true, notification: Bool) {
    self.kind = kind
    self.source = source
    self.meta = Command.MetaData(
      id: id, name: name, isEnabled: true, notification: notification)
  }
}

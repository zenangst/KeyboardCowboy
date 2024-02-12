import Foundation

struct MacroAction: Identifiable, Codable, Hashable, Sendable  {
  let id: String
  let kind: Kind

  enum Kind: Codable {
    case record
    case remove
  }

  init(id: String, kind: Kind) {
    self.id = id
    self.kind = kind
  }

  init(_ kind: Kind, id: String = UUID().uuidString) {
    self.id = id
    self.kind = kind
  }

  static var record: MacroAction { MacroAction(.record) }
  static var remove: MacroAction { MacroAction(.remove) }
}

import Foundation

struct UIElementCommand: MetaDataProviding {
  enum Kind: Codable, Hashable {
    case any(predicate: Predicate)
    case button(predicate: Predicate)
    case radio(predicate: Predicate)
  }

  struct Predicate: Codable, Hashable {
    let value: String
  }

  var meta: Command.MetaData
  var kind: Kind
}

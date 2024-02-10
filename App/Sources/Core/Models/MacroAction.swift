import Foundation

struct MacroAction: Identifiable, Codable, Hashable, Sendable  {
  let id: String
  let kind: Kind

  enum Kind: Codable {
    case list
    case record
    case remove
  }
}

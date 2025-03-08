import Foundation

extension ScriptCommand {
  enum Variant: Codable, Hashable, Sendable {
    case regular
    case jxa
  }
}

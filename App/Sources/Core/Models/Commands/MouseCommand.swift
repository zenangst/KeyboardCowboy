import Foundation

struct MouseCommand: Codable, MetaDataProviding {
  enum Kind: Codable, Hashable {
    case click(UIElement)
  }

  enum UIElement: Codable {
    case focused
  }

  var meta: Command.MetaData
  var kind: Kind

  static func empty() -> MouseCommand {
    .init(meta: .init(), kind: .click(.focused))
  }
}

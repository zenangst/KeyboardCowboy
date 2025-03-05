import Foundation

struct MouseCommand: Identifiable, Codable, MetaDataProviding {
  var meta: Command.MetaData
  var kind: Kind

  func copy() -> MouseCommand {
    MouseCommand(meta: self.meta.copy(), kind: self.kind)
  }

  static func empty() -> MouseCommand {
    .init(meta: .init(), kind: .click(.focused(.center)))
  }
}

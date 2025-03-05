import Foundation

struct BundledCommand: MetaDataProviding {
  var kind: Kind
  var meta: Command.MetaData

  init(_ kind: Kind, meta: Command.MetaData) {
    self.kind = kind
    self.meta = meta
  }

  func copy() -> BundledCommand {
    .init(kind.copy(), meta: meta.copy())
  }
}

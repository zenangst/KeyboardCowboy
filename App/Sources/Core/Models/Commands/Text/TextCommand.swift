import Foundation

struct TextCommand: MetaDataProviding {
  var kind: Kind

  init(_ kind: Kind) {
    self.kind = kind
  }

  func copy() -> TextCommand {
    TextCommand(kind.copy())
  }
}

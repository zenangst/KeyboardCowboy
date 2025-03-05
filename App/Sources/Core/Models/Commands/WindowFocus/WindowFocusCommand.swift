import Foundation

struct WindowFocusCommand: MetaDataProviding {
  var kind: Kind
  var meta: Command.MetaData

  func copy() -> WindowFocusCommand {
    WindowFocusCommand(kind: kind, meta: meta.copy())
  }
}

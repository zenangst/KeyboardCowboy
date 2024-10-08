import Foundation

struct BundledCommand: MetaDataProviding {
  enum Kind: Codable, Hashable, Identifiable {
    case workspace(WorkspaceCommand)
    case focusOnApp(FocusOnAppCommand)

    var id: String {
      switch self {
      case .focusOnApp(let focusOnApp): focusOnApp.id
      case .workspace(let workspace): workspace.id
      }
    }

    func copy() -> Kind {
      switch self {
      case .focusOnApp(let command): .focusOnApp(command.copy())
      case .workspace(let workspace): .workspace(workspace.copy())
      }
    }
  }
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

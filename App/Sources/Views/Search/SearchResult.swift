import Foundation

struct SearchResult: Hashable, Identifiable {
  enum Kind: Hashable {
    case workflow(Workflow)
    case command(Command)
  }

  var id: String {
    switch kind {
    case .command(let command):
      return command.id
    case .workflow(let workflow):
      return workflow.id
    }
  }
  let name: String
  let kind: Kind
}

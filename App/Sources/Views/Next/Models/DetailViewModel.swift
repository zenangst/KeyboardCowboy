import SwiftUI

enum DetailViewState: Hashable, Identifiable {
  var id: String {
    switch self {
    case .empty:
      return UUID().uuidString
    case .single(let viewModel):
      return viewModel.id
    case .multiple(let viewModels):
      return viewModels.map { $0.id }.joined()
    }
  }

  case single(DetailViewModel)
  case multiple([DetailViewModel])
  case empty
}

struct DetailViewModel: Hashable, Identifiable {
  let id: String
  var name: String
  var isEnabled: Bool
  var trigger: Trigger?
  var commands: [CommandViewModel]

  enum Trigger: Hashable {
    case applications(String)
    case keyboardShortcuts([String])
  }

  struct KeyboardShortcut: Hashable {
    let displayValue: String
  }

  struct CommandViewModel: Hashable, Identifiable {
    let id: String
    var name: String
    let image: NSImage?
    var isEnabled: Bool
  }
}

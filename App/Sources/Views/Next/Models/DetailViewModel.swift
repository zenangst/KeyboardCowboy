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
    case applications([DetailViewModel.ApplicationTrigger])
    case keyboardShortcuts([KeyboardShortcut])
  }

  struct ApplicationTrigger: Hashable, Identifiable {
    public var id: String
    public var name: String
    public var image: NSImage
    public var contexts: [Context]

    public enum Context: String, Hashable, Codable, CaseIterable, Identifiable {
      public var id: String { rawValue }

      case closed, launched, frontMost

      public var displayValue: String {
        switch self {
        case .launched:
          return "Launched"
        case .closed:
          return "Closed"
        case .frontMost:
          return "When in front most"
        }
      }
    }
  }

  struct KeyboardShortcut: Hashable {
    let id: String
    let displayValue: String
    let modifier: ModifierKey
  }

  struct CommandViewModel: Hashable, Identifiable {
    let id: String
    var name: String
    let image: NSImage?
    var isEnabled: Bool
  }
}

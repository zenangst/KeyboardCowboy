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
  // Workflow.Id
  let id: String
  var name: String
  var isEnabled: Bool
  var trigger: Trigger?
  var commands: [CommandViewModel]
  var flow: Flow = .concurrent

  enum Flow: String, CaseIterable, Hashable, Identifiable {
    var id: String { rawValue }
    case concurrent = "Concurrent"
    case serial = "Serial"
  }

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

  struct KeyboardShortcut: Hashable, Identifiable {
    let id: String
    var displayValue: String
    let modifier: ModifierKey
  }

  struct CommandViewModel: Hashable, Identifiable {
    let id: String
    var name: String
    var kind: Kind
    var image: NSImage?
    var isEnabled: Bool

    enum Kind: Hashable, Identifiable {
      var id: String {
        switch self {
        case .application:
          return "application"
        case .plain:
          return "plain"
        case .open:
          return "open"
        case .script(let kind):
          switch kind {
          case .inline:
            return "inline"
          case .path:
            return "path"
          }
        case .keyboard:
          return "rebinding"
        case .shortcut:
          return "shortcut"
        case .type:
          return "type"
        }

      }
      case application(action: String, inBackground: Bool, hideWhenRunning: Bool, ifNotRunning: Bool)
      case open(path: String, applicationPath: String?, appName: String?)
      case keyboard(key: String, modifiers: [ModifierKey])
      case script(ScriptKind)
      case plain
      case shortcut
      case type(input: String)
    }

    enum ScriptKind: Hashable, Identifiable {
      var id: String {
        switch self {
        case .inline(let id, _, _),
             .path(let id, _, _):
          return id
        }
      }

      case inline(id: String, source: String, type: String)
      case path(id: String, source: String, fileExtension: String)
    }
  }
}

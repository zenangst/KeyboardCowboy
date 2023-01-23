import SwiftUI

enum DetailViewState: Hashable, Identifiable {
  var id: String {
    switch self {
    case .empty:
      return "0"
    case .single:
      return "1"
    case .multiple(let viewModels):
      return viewModels.map { $0.id }.joined()
    }
  }

  case single
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
    let modifiers: [ModifierKey]
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
      case keyboard(keys: [KeyboardShortcut])
      case script(ScriptKind)
      case plain
      case shortcut
      case type(input: String)

      var scriptSource: String {
        get {
          if case .script(let kind) = self {
            return kind.source
          }
          return ""
        }
        set {
          if case .script(let kind) = self {
            switch kind {
            case .inline(let id, _, let scriptExtension):
              self = .script(.inline(id: id, source: newValue, scriptExtension: scriptExtension))
            case .path(let id, _, let scriptExtension):
              self = .script(.path(id: id, source: newValue, scriptExtension: scriptExtension))
            }
          }
        }
      }
    }

    enum ScriptKind: Hashable, Identifiable {
      var id: String {
        get {
          switch self {
          case .inline(let id, _, _),
               .path(let id, _, _):
            return id
          }
        }
        set {
          switch self {
          case .inline(_, let source, let scriptExtension):
            self = .inline(id: newValue, source: source, scriptExtension: scriptExtension)
          case .path(_, let source, let scriptExtension):
            self = .path(id: newValue, source: source, scriptExtension: scriptExtension)
          }
        }
      }

      var source: String {
        get {
          switch self {
          case .inline(_, let source,  _),
               .path(_, let source,  _):
            return source
          }
        }
        set {
          switch self {
          case .inline(let id, _, let scriptExtension):
            self = .inline(id: id, source: newValue, scriptExtension: scriptExtension)
          case .path(let id, _, let scriptExtension):
            self = .path(id: id, source: newValue, scriptExtension: scriptExtension)
          }
        }
      }

      case inline(id: String, source: String, scriptExtension: ScriptCommand.Kind)
      case path(id: String, source: String, scriptExtension: ScriptCommand.Kind)
    }
  }
}

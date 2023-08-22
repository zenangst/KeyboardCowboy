import SwiftUI
import Apps

enum DetailViewState: Hashable, Identifiable, Equatable {
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

struct IconViewModel: Identifiable, Codable, Hashable, Equatable, Sendable {
  var id: String { path  }
  let bundleIdentifier: String
  let path: String

  internal init(bundleIdentifier: String, path: String) {
    self.bundleIdentifier = bundleIdentifier
    self.path = path
  }
}

struct DetailViewModel: Hashable, Identifiable, Equatable {
  // Workflow.Id
  let id: String
  var name: String
  var isEnabled: Bool
  var trigger: Trigger?
  var commands: [CommandViewModel]
  var execution: Execution

  enum Execution: String, CaseIterable, Hashable, Identifiable, Equatable {
    var id: String { rawValue }
    case concurrent = "Concurrent"
    case serial = "Serial"
  }

  enum Trigger: Hashable, Equatable {
    case applications([DetailViewModel.ApplicationTrigger])
    case keyboardShortcuts(DetailViewModel.KeyboardTrigger)
  }

  struct ApplicationTrigger: Codable, Hashable, Identifiable, Equatable {
    var id: String
    var name: String
    var application: Application
    var contexts: [Context]

    var icon: IconViewModel {
      IconViewModel(bundleIdentifier: application.bundleIdentifier, path: application.path)
    }

    enum Context: String, Hashable, Codable, CaseIterable, Identifiable {
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

  struct KeyboardTrigger: Codable, Hashable, Equatable {
    var passthrough: Bool
    var holdDuration: Double?
    var shortcuts: [KeyShortcut]
  }
}

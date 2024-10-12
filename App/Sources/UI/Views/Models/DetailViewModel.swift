import Apps
import Bonzai
import SwiftUI

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

  case single(DetailViewModel)
  case multiple([DetailViewModel])
  case empty
}

struct DetailViewModel: Hashable, Identifiable, Equatable {
  // Workflow.Id
  var id: String { info.id }
  let info: Info
  let commandsInfo: CommandsInfo

  var trigger: Trigger = .empty

  struct Info: Hashable, Identifiable, Equatable {
    let id: String
    var name: String
    var isEnabled: Bool
  }

  struct CommandsInfo: Hashable, Identifiable, Equatable {
    let id: String
    var commands: [CommandViewModel]
    var execution: Execution
  }

  enum Execution: String, CaseIterable, Hashable, Identifiable, Equatable {
    var id: String { rawValue }
    case concurrent = "Concurrent"
    case serial = "Serial"
  }

  enum Trigger: Hashable, Equatable, Identifiable {
    var id: String {
      switch self {
      case .applications(let array): array.map(\.id).joined()
      case .keyboardShortcuts(let keyboardTrigger): keyboardTrigger.shortcuts.map(\.id).joined()
      case .snippet(let trigger): trigger.id
      case .empty: "empty"
      }
    }

    case applications([DetailViewModel.ApplicationTrigger])
    case keyboardShortcuts(DetailViewModel.KeyboardTrigger)
    case snippet(DetailViewModel.SnippetTrigger)
    case empty
  }

  struct ApplicationTrigger: Codable, Hashable, Identifiable, Equatable, Transferable {
    static var transferRepresentation: some TransferRepresentation {
      CodableRepresentation(contentType: .applicationTrigger)
    }

    var id: String
    var name: String
    var application: Application
    var contexts: [Context]

    var icon: Icon {
      Icon(bundleIdentifier: application.bundleIdentifier, path: application.path)
    }

    enum Context: String, Hashable, Codable, CaseIterable, Identifiable {
      public var id: String { rawValue }

      case closed, launched, frontMost, resignFrontMost

      public var displayValue: String {
        switch self {
        case .launched:  "Launched"
        case .closed:    "Closed"
        case .frontMost: "When in front most"
        case .resignFrontMost: "When resigns front most"
        }
      }
    }
  }

  struct KeyboardTrigger: Codable, Hashable, Equatable {
    var passthrough: Bool
    var holdDuration: Double?
    var shortcuts: [KeyShortcut]
  }

  struct SnippetTrigger: Codable, Hashable, Equatable {
    var id: String
    var text: String
  }
}

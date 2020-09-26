import Foundation
import LogicFramework
import ViewKit

protocol CommandViewModelMapping {
  func map(_ models: [Command]) -> [CommandViewModel]
}

class CommandViewModelMapper: CommandViewModelMapping {
  func map(_ models: [Command]) -> [CommandViewModel] {
    models.compactMap(map(_:))
  }

  func map(_ command: Command) -> CommandViewModel {
    let viewModel: CommandViewModel
    switch command {
    case .application(let applicationCommand):
      viewModel = .init(id: applicationCommand.id, name: applicationCommand.application.bundleName)
    case .keyboard(let keyboardCommand):
      viewModel = .init(id: keyboardCommand.id, name: keyboardCommand.keyboardShortcut.key)
    case .open(let openCommand):
      viewModel = .init(id: openCommand.id, name: openCommand.path)
    case .script(let scriptCommand):
      switch scriptCommand {
      case .appleScript(let source, let id):
        switch source {
        case .inline(let value):
          viewModel = .init(id: id, name: value)
        case .path(let source):
          viewModel = .init(id: id, name: source)
        }
      case .shell(let source, let id):
        switch source {
        case .inline(let value):
          viewModel = .init(id: id, name: value)
        case .path(let source):
          viewModel = .init(id: id, name: source)
        }
      }
    }

    return viewModel
  }
}

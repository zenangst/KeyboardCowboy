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

  private func map(_ command: Command) -> CommandViewModel {
    let viewModel: CommandViewModel
    switch command {
    case .application(let applicationCommand):
      viewModel = .init(id: applicationCommand.id,
                        name: applicationCommand.application.bundleName,
                        kind: .application(
                          path: applicationCommand.application.path,
                          bundleIdentifier: applicationCommand.application.bundleIdentifier))
    case .keyboard(let keyboardCommand):
      viewModel = .init(id: keyboardCommand.id, name: keyboardCommand.keyboardShortcut.key, kind: .keyboard)
    case .open(let openCommand):
      if openCommand.path.contains("://") {
        viewModel = .init(id: openCommand.id, name: openCommand.path,
                          kind: .openUrl(url: openCommand.path, application: openCommand.application?.path ?? ""))
      } else {
        viewModel = .init(id: openCommand.id, name: openCommand.path,
                          kind: .openFile(path: openCommand.path, application: openCommand.application?.path ?? ""))
      }
    case .script(let scriptCommand):
      viewModel = mapScriptCommand(scriptCommand)
    }

    return viewModel
  }

  private func mapScriptCommand(_ scriptCommand: ScriptCommand) -> CommandViewModel {
    let viewModel: CommandViewModel
    switch scriptCommand {
    case .appleScript(let source, let id):
      switch source {
      case .inline(let value):
        viewModel = .init(id: id, name: value, kind: .appleScript)
      case .path(let source):
        viewModel = .init(id: id, name: source, kind: .appleScript)
      }
    case .shell(let source, let id):
      switch source {
      case .inline(let value):
        viewModel = .init(id: id, name: value, kind: .shellScript)
      case .path(let source):
        viewModel = .init(id: id, name: source, kind: .shellScript)
      }
    }

    return viewModel
  }
}

import Foundation
import LogicFramework
import ViewKit
import ModelKit

protocol CommandViewModelMapping {
  func map(_ models: [Command]) -> [CommandViewModel]
  func map(_ command: Command) -> CommandViewModel
}

class CommandViewModelMapper: CommandViewModelMapping {
  let installedApplications: [Application]

  init(installedApplications: [Application] = []) {
    self.installedApplications = installedApplications
  }

  func map(_ models: [Command]) -> [CommandViewModel] {
    models.compactMap(map(_:))
  }

  func map(_ command: Command) -> CommandViewModel {
    let viewModel: CommandViewModel
    switch command {
    case .application(let applicationCommand):
      viewModel = mapApplicationCommand(applicationCommand)
    case .keyboard(let keyboardCommand):
      viewModel = mapKeyboardCommand(keyboardCommand)
    case .open(let openCommand):
      if openCommand.path.contains("://") {
        return mapOpenFileCommand(openCommand)
      } else {
        return mapOpenUrlCommand(openCommand)
      }
    case .script(let scriptCommand):
      viewModel = mapScriptCommand(scriptCommand)
    }

    return viewModel
  }

  private func mapApplicationCommand(_ command: ApplicationCommand) -> CommandViewModel {
    var applicationPath = command.application.path

    let fileManager = FileManager()
    if !fileManager.fileExists(atPath: applicationPath),
       let application = installedApplications
        .first(where: { $0.bundleIdentifier == command.application.bundleIdentifier }) {
      applicationPath = application.path
    }

    return CommandViewModel(id: command.id,
                     name: command.application.bundleName,
                     kind: .application(
                      ApplicationViewModel(id: command.id,
                                           bundleIdentifier: command.application.bundleIdentifier,
                                           name: command.application.bundleName,
                                           path: applicationPath)))
  }

  private func mapKeyboardCommand(_ command: KeyboardCommand) -> CommandViewModel {
    let modifiers = command.keyboardShortcut.modifiers ?? []
    var name = "Run Keyboard Shortcut: "
      name += modifiers.compactMap({ $0.pretty }).joined()
    name += command.keyboardShortcut.key
    return CommandViewModel(
      id: command.id,
      name: name,
      kind: .keyboard(KeyboardShortcutViewModel(id: command.id,
                                                index: 0,
                                                key: command.keyboardShortcut.key,
                                                modifiers: modifiers)))
  }

  private func mapOpenFileCommand(_ openCommand: OpenCommand) -> CommandViewModel {
    var applicationViewModel: ApplicationViewModel?
    if let application = openCommand.application {
      applicationViewModel = ApplicationViewModel(
        id: openCommand.id,
        bundleIdentifier: application.bundleIdentifier,
        name: application.bundleName,
        path: application.path)
    }

    var url: URL = URL(fileURLWithPath: openCommand.path)
    if let remoteUrl = URL(string: openCommand.path),
       !remoteUrl.isFileURL {
       url = remoteUrl
    }

    return  CommandViewModel(
      id: openCommand.id,
      name: openCommand.path,
      kind: .openUrl(OpenURLViewModel(id: openCommand.id,
                                      url: url,
                                      application: applicationViewModel)))
  }

  private func mapOpenUrlCommand(_ openCommand: OpenCommand) -> CommandViewModel {
    var applicationViewModel: ApplicationViewModel?
    if let application = openCommand.application {
      applicationViewModel = ApplicationViewModel(
        id: openCommand.id,
        bundleIdentifier: application.bundleIdentifier,
        name: application.bundleName,
        path: application.path)
    }

    return CommandViewModel(
      id: openCommand.id,
      name: openCommand.path,
      kind: .openFile(OpenFileViewModel(id: openCommand.id, path: openCommand.path,
                                        application: applicationViewModel)) )
  }

  private func mapScriptCommand(_ scriptCommand: ScriptCommand) -> CommandViewModel {
    let viewModel: CommandViewModel
    switch scriptCommand {
    case .appleScript(let source, let id):
      switch source {
      case .inline(let value):
        viewModel = .init(id: id, name: value, kind: .appleScript(AppleScriptViewModel(id: id, path: value)))
      case .path(let source):
        viewModel = .init(id: id, name: source, kind: .appleScript(AppleScriptViewModel(id: id, path: source)))
      }
    case .shell(let source, let id):
      switch source {
      case .inline(let value):
        viewModel = .init(id: id, name: value, kind: .shellScript(ShellScriptViewModel(id: id, path: value)))
      case .path(let source):
        viewModel = .init(id: id, name: source, kind: .shellScript(ShellScriptViewModel(id: id, path: source)))
      }
    }

    return viewModel
  }
}

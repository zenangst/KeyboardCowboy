import Cocoa

final class DetailModelMapper {
  private let applicationStore: ApplicationStore

  init(_ applicationStore: ApplicationStore) {
    self.applicationStore = applicationStore
  }

  func map(_ workflows: [Workflow]) -> [DetailViewModel] {
    let start = CACurrentMediaTime()
    defer {
      let end = CACurrentMediaTime()
      Swift.print("⏱️ time: \(end - start)")
    }

    var viewModels = [DetailViewModel]()
    viewModels.reserveCapacity(workflows.count)
    for workflow in workflows {
      var workflowCommands = [DetailViewModel.CommandViewModel]()
      workflowCommands.reserveCapacity(workflow.commands.count)
      for command in workflow.commands {
        let workflowCommand = map(command)
        workflowCommands.append(workflowCommand)
      }

      let viewModel = DetailViewModel(
        id: workflow.id,
        name: workflow.name,
        isEnabled: workflow.isEnabled,
        trigger: workflow.trigger?.asViewModel(),
        commands: workflowCommands)
      viewModels.append(viewModel)
    }

    return viewModels
  }

  func map(_ command: Command) -> DetailViewModel.CommandViewModel {
    let kind: DetailViewModel.CommandViewModel.Kind
    let name: String
    switch command {
    case .application(let applicationCommand):
      let inBackground = applicationCommand.modifiers.contains(.background)
      let hideWhenRunning = applicationCommand.modifiers.contains(.hidden)
      let onlyIfRunning = applicationCommand.modifiers.contains(.onlyIfNotRunning)
      kind = .application(action: applicationCommand.action.displayValue,
                          inBackground: inBackground,
                          hideWhenRunning: hideWhenRunning,
                          ifNotRunning: onlyIfRunning)

      name = applicationCommand.name.isEmpty
      ? applicationCommand.application.displayName
      : command.name
    case .builtIn(_):
      kind = .plain
      name = command.name
    case .keyboard(let keyboardCommand):
      kind =  .keyboard(keys: keyboardCommand.keyboardShortcuts)
      name = command.name
    case .open(let openCommand):
      let appName: String?
      let appPath: String?
      if let app = openCommand.application {
        appName = app.displayName
        appPath = app.path
      } else if let url = URL(string: openCommand.path),
                let appUrl = NSWorkspace.shared.urlForApplication(toOpen: url),
                let app = applicationStore.application(at: appUrl) {
        appName = app.displayName
        appPath = app.path
      } else {
        appName = nil
        appPath = nil
      }

      kind = .open(path: openCommand.path, applicationPath: appPath, appName: appName)

      if openCommand.isUrl {
        name = openCommand.path
      } else {
        name = openCommand.path
      }
    case .shortcut(_):
      kind = .shortcut
      name = command.name
    case .script(let script):
      switch script {
      case .appleScript(_ , _, _, let source),
          .shell(_ , _, _, let source):
        switch source {
        case .path(let source):
          kind = .script(.path(id: script.id,
                               source: source,
                               scriptExtension: script.kind))
        case .inline(let source):
          kind = .script(.inline(id: script.id, source: source, scriptExtension: script.kind))
        }
      }
      name = command.name
    case .type(let type):
      kind = .type(input: type.input)
      name = command.name
    }

    return DetailViewModel.CommandViewModel(
      id: command.id,
      name: name,
      kind: kind,
      image: command.nsImage,
      isEnabled: command.isEnabled
    )
  }
}

private extension Command {
  var nsImage: NSImage? {
    switch self {
    case .application(let command):
      return NSWorkspace.shared.icon(forFile: command.application.path)
    case .builtIn:
      return nil
    case .keyboard:
      return nil
    case .open(let command):
      let nsImage: NSImage
      if let application = command.application, command.isUrl {
        nsImage = NSWorkspace.shared.icon(forFile: application.path)
      } else if command.isUrl {
        nsImage = NSWorkspace.shared.icon(forFile: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app")
      } else {
        nsImage = NSWorkspace.shared.icon(forFile: command.path)
      }
      return nsImage
    case .script(let kind):
      return NSWorkspace.shared.icon(forFile: kind.path)
    case .shortcut:
      return nil
    case .type:
      return nil
    }
  }
}

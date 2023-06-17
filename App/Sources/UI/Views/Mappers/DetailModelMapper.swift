import Cocoa

final class DetailModelMapper {
  private let applicationStore: ApplicationStore

  init(_ applicationStore: ApplicationStore) {
    self.applicationStore = applicationStore
  }

  func map(_ workflows: [Workflow]) -> [DetailViewModel] {
    var viewModels = [DetailViewModel]()
    viewModels.reserveCapacity(workflows.count)
    for workflow in workflows {
      var workflowCommands = [DetailViewModel.CommandViewModel]()
      workflowCommands.reserveCapacity(workflow.commands.count)
      for command in workflow.commands {
        let workflowCommand = map(command)
        workflowCommands.append(workflowCommand)
      }

      let execution: DetailViewModel.Execution
      switch workflow.execution {
      case .concurrent:
        execution = .concurrent
      case .serial:
        execution = .serial
      }

      let trigger = workflow.trigger?.asViewModel()

      let viewModel = DetailViewModel(
        id: workflow.id,
        name: workflow.name,
        isEnabled: workflow.isEnabled,
        trigger: trigger,
        commands: workflowCommands,
        execution: execution)
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
    case .menuBar(let menubarCommand):
      kind = .menuBar(tokens: menubarCommand.tokens)
      name = command.name
    case .open(let openCommand):
      let appName: String?
      let appPath: String?
      if let app = openCommand.application {
        appName = app.displayName
        appPath = app.path
      } else if openCommand.isUrl,
                let url = URL(string: openCommand.path),
                let appUrl = NSWorkspace.shared.urlForApplication(toOpen: url),
                let app = applicationStore.application(at: appUrl)
      {
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
      let source: String
      switch script.source {
      case .path(let string):
        source = string
      case .inline(let string):
        source = string
      }

      kind = .script(.inline(id: script.id, source: source, scriptExtension: script.kind))
      name = command.name
    case .type(let type):
      kind = .type(input: type.input)
      name = command.name
    case .systemCommand(let systemCommand):
      kind = .systemCommand(kind: systemCommand.kind)
      name = command.name
    }

    return DetailViewModel.CommandViewModel(
      id: command.id,
      name: name,
      kind: kind,
      icon: command.icon,
      delay: command.meta.delay,
      isEnabled: command.isEnabled,
      notify: command.notification
    )
  }
}

private extension Command {
  var icon: IconViewModel? {
    switch self {
    case .application(let command):
      return .init(bundleIdentifier: command.application.bundleIdentifier,
                   path: command.application.path)
    case .menuBar:
      let path = "/System/Library/PreferencePanes/Appearance.prefPane"
      return .init(bundleIdentifier: path, path: path)
    case .builtIn, .keyboard:
      return nil
    case .open(let command):
      let path: String
      if command.isUrl {
        path = "/System/Library/SyncServices/Schemas/Bookmarks.syncschema/Contents/Resources/com.apple.Bookmarks.icns"
      } else {
        path = command.path
      }
      return .init(bundleIdentifier: path, path: path)
    case .script(let scriptCommand):
      let path: String
      switch scriptCommand.source {
      case .path(let sourcePath):
        path = sourcePath
      case .inline:
        path = ""
      }

      return .init(bundleIdentifier: path, path: path)
    case .shortcut:
      return nil
    case .type:
      return nil
    case .systemCommand(let command):
      let path: String
      switch command.kind {
      case .applicationWindows:
        path = "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindowFront, .moveFocusToNextWindowGlobal:
        path = "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToPreviousWindowFront, .moveFocusToPreviousWindowGlobal:
        path = "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindow:
        path = "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToPreviousWindow:
        path = "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .missionControl:
        path = "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .showDesktop:
        path = "/System/Library/CoreServices/Dock.app/Contents/Resources/Dock.icns"
      }

      return .init(bundleIdentifier: path, path: path)
    }
  }
}

extension Workflow.Trigger {
  func asViewModel() -> DetailViewModel.Trigger {
    switch self {
    case .application(let triggers):
      return .applications(
        triggers.map { trigger in
          DetailViewModel.ApplicationTrigger(id: trigger.id,
                                             name: trigger.application.displayName,
                                             application: trigger.application,
                                             contexts: trigger.contexts.map {
            switch $0 {
            case .closed:
              return .closed
            case .frontMost:
              return .frontMost
            case .launched:
              return .launched
            }
          })
        }
      )
    case .keyboardShortcuts(let shortcuts):
      return .keyboardShortcuts(shortcuts)
    }
  }
}

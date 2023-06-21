import Apps
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
      var workflowCommands = [CommandViewModel]()
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

  func map(_ command: Command) -> CommandViewModel {
    CommandViewModel(meta: command.meta.viewModel(command),
                     kind: command.viewModel(applicationStore))
  }
}

private extension Command.MetaData {
  func viewModel(_ command: Command) -> CommandViewModel.MetaData {
    CommandViewModel.MetaData(id: id, name: name,
                              isEnabled: isEnabled,
                              notification: notification,
                              icon: command.icon)
  }
}

private extension Command {
  func viewModel(_ applicationStore: ApplicationStore) -> CommandViewModel.Kind {
    let kind: CommandViewModel.Kind
    switch self {
    case .application(let applicationCommand):
      let inBackground = applicationCommand.modifiers.contains(.background)
      let hideWhenRunning = applicationCommand.modifiers.contains(.hidden)
      let ifNotRunning = applicationCommand.modifiers.contains(.onlyIfNotRunning)
      kind = .application(.init(id: applicationCommand.id, action: applicationCommand.action.displayValue,
                                inBackground: inBackground, hideWhenRunning: hideWhenRunning, ifNotRunning: ifNotRunning))

    case .builtIn(_):
      kind = .plain
    case .keyboard(let keyboardCommand):
      kind =  .keyboard(.init(id: keyboardCommand.id, keys: keyboardCommand.keyboardShortcuts))
    case .menuBar(let menubarCommand):
      kind = .menuBar(.init(id: menubarCommand.id, tokens: menubarCommand.tokens))
    case .open(let openCommand):
      let applications = applicationStore.applicationsToOpen(openCommand.path)
      kind = .open(.init(id: openCommand.id,
                         path: openCommand.path,
                         applicationPath: openCommand.application?.path,
                         appName: openCommand.application?.displayName,
                         applications: applications))
    case .shortcut(let shortcut):
      kind = .shortcut(.init(id: shortcut.id, shortcutIdentifier: shortcut.shortcutIdentifier))
    case .script(let script):
      switch script.source {
      case .path(let source):
        kind = .script(.init(id: script.id, source: .path(source), scriptExtension: script.kind))
      case .inline(let source):
        kind = .script(.init(id: script.id, source: .inline(source), scriptExtension: script.kind))
      }
    case .type(let type):
      kind = .type(.init(id: type.id, input: type.input))
    case .systemCommand(let systemCommand):
      kind = .systemCommand(.init(id: systemCommand.id, kind: systemCommand.kind))
    }

    return kind
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
    case .keyboardShortcuts(let trigger):
      return .keyboardShortcuts(.init(passthrough: trigger.passthrough, shortcuts: trigger.shortcuts))
    }
  }
}

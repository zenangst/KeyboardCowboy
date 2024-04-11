import Apps
import Bonzai
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

      let viewModel = DetailViewModel(
        info: DetailViewModel.Info(id: workflow.id, name: workflow.name, isEnabled: workflow.isEnabled),
        commandsInfo: DetailViewModel.CommandsInfo(id: workflow.id, commands: workflowCommands, execution: execution),
        trigger: workflow.trigger?.asViewModel() ?? .empty)
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
    CommandViewModel.MetaData(
      id: id,
      delay: command.delay,
      name: name,
      namePlaceholder: command.name,
      isEnabled: isEnabled,
      notification: notification,
      icon: command.icon
    )
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

    case .builtIn(let builtInCommand):
      kind = .builtIn(.init(id: builtInCommand.id, name: builtInCommand.name, kind: builtInCommand.kind))
    case .keyboard(let keyboardCommand):
      kind =  .keyboard(.init(id: keyboardCommand.id, keys: keyboardCommand.keyboardShortcuts))
    case .menuBar(let menubarCommand):
      kind = .menuBar(.init(id: menubarCommand.id, application: menubarCommand.application, tokens: menubarCommand.tokens))
    case .mouse(let mouseCommand):
      kind = .mouse(.init(id: mouseCommand.id, kind: mouseCommand.kind))
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
    case .text(let text):
      switch text.kind {
      case .insertText(let typeCommand):
        kind = .text(.init(kind: .type(.init(id: typeCommand.input, mode: typeCommand.mode, input: typeCommand.input))))
      }
    case .systemCommand(let systemCommand):
      kind = .systemCommand(.init(id: systemCommand.id, kind: systemCommand.kind))
    case .uiElement(let uiElementCommand):
      kind = .uiElement(uiElementCommand)
    case .windowManagement(let windowCommand):
      kind = .windowManagement(.init(id: windowCommand.id, kind: windowCommand.kind, animationDuration: windowCommand.animationDuration))
    }

    return kind
  }
}

private extension Command {
  var icon: Icon? {
    switch self {
    case .application(let command):
      return .init(bundleIdentifier: command.application.bundleIdentifier,
                   path: command.application.path)
    case .builtIn:
      let path = Bundle.main.bundleURL.path
      return .init(bundleIdentifier: path, path: path)
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
    case .systemCommand(let command):
      return .init(bundleIdentifier: command.kind.iconPath, path: command.kind.iconPath)
    default:
      return nil
    }
  }
}

extension Workflow.Trigger {
  func asViewModel() -> DetailViewModel.Trigger {
    switch self {
    case .application(let triggers):
        .applications(
          triggers.map { trigger in
            DetailViewModel.ApplicationTrigger(id: trigger.id,
                                               name: trigger.application.displayName,
                                               application: trigger.application,
                                               contexts: trigger.contexts.map {
              switch $0 {
              case .closed:          .closed
              case .frontMost:       .frontMost
              case .launched:        .launched
              case .resignFrontMost: .resignFrontMost
              }
            })
          }
        )
    case .keyboardShortcuts(let trigger):
        .keyboardShortcuts(.init(passthrough: trigger.passthrough,
                                 holdDuration: trigger.holdDuration,
                                 shortcuts: trigger.shortcuts))
    case .snippet(let trigger):
        .snippet(.init(id: trigger.id, text: trigger.text))
    }
  }
}

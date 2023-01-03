import SwiftUI

final class DetailCoordinator {
  let applicationStore: ApplicationStore
  let contentStore: ContentStore
  let keyboardCowboyEngine: KeyboardCowboyEngine
  let groupStore: GroupStore
  let publisher: DetailPublisher = .init(.empty)

  init(applicationStore: ApplicationStore,
       contentStore: ContentStore,
       keyboardCowboyEngine: KeyboardCowboyEngine,
       groupStore: GroupStore) {
    self.applicationStore = applicationStore
    self.keyboardCowboyEngine = keyboardCowboyEngine
    self.contentStore = contentStore
    self.groupStore = groupStore
  }

  func handle(_ action: ContentView.Action) {
    switch action {
    case .selectWorkflow(let content):
      Task { await render(content) }
    default:
      break
    }
  }

  @MainActor
  func handle(_ action: DetailView.Action) {
    Task {
      switch action {
      case .singleDetailView(let action):
        switch action {
        case .commandView(let action):
          await handleCommandAction(action)
        case .moveCommand(let workflowId, let fromOffsets, let toOffset):
          guard var workflow = groupStore.workflow(withId: workflowId) else { return }
          workflow.commands.move(fromOffsets: fromOffsets, toOffset: toOffset)
          contentStore.updateWorkflows([workflow])
        case .updateName(let name, let workflowId):
          guard var workflow = groupStore.workflow(withId: workflowId) else { return }
          workflow.name = name
          contentStore.updateWorkflows([workflow])
        case .addCommand:
          break
        case .trigger(let action):
          switch action {
          case .addKeyboardShortcut:
            Swift.print("Add keyboard shortcut")
          case .removeKeyboardShortcut:
            Swift.print("Remove keyboard shortcut")
          case .addApplication:
            Swift.print("Add application trigger")
          }
        case .applicationTrigger(let action):
          switch action {
          case .addApplicationTrigger(let application):
            Swift.print("Add application trigger: \(application)")
          case .removeApplicationTrigger(let trigger):
            Swift.print("Remove trigger: \(trigger)")
          }
        }
      }
    }
  }

  func handleCommandAction(_ commandAction: CommandView.Action) async {
    guard var workflow = groupStore.workflow(withId: commandAction.workflowId) else {
      fatalError("Unable to find workflow.")
    }

    guard var command: Command = workflow.commands.first(where: { $0.id == commandAction.commandId }) else {
      fatalError("Unable to find command.")
    }

    switch commandAction {
    case .run(_, _):
      break
    case .remove(_, let commandId):
      var workflow = workflow
      workflow.commands.removeAll(where: { $0.id == commandId })
      await groupStore.receive([workflow])
    case .modify(let kind):
      switch kind {
      case .application(let action, _, _):
        guard case .application(var applicationCommand) = command else {
          fatalError("Wrong command type")
        }

        switch action {
        case .changeApplication(let application):
          applicationCommand.application = application
          command = .application(applicationCommand)
          workflow.updateOrAddCommand(command)
          await groupStore.receive([workflow])
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
          await groupStore.receive([workflow])
        case .changeApplicationAction(let action):
          switch action {
          case .open:
            applicationCommand.action = .open
          case .close:
            applicationCommand.action = .close
          }
          command = .application(applicationCommand)
          workflow.updateOrAddCommand(command)
          await groupStore.receive([workflow])
        case .changeApplicationModifier(let modifier, let newValue):
          if newValue {
            applicationCommand.modifiers.insert(modifier)
          } else {
            applicationCommand.modifiers.remove(modifier)
          }
          command = .application(applicationCommand)
          workflow.updateOrAddCommand(command)
          await groupStore.receive([workflow])
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: workflow)
        }
      case .keyboard(let action, _, _):
        switch action {
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
          await groupStore.receive([workflow])
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: workflow)
        }
      case .open(let action, _, _):
        switch action {
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
          await groupStore.receive([workflow])
        case .openWith:
          break
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: workflow)
        case .reveal(let path):
          NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }
      case .script(let action, _, _):
        switch action {
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
          await groupStore.receive([workflow])
        case .open(let source):
          Task {
            let path = (source as NSString).expandingTildeInPath
            await keyboardCowboyEngine.run([
              .open(.init(path: path))
            ], serial: true)
          }
        case .reveal(let path):
          NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        case .edit:
          break
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: workflow)
        }
      case .shortcut(let action, _, _):
        switch action {
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
          await groupStore.receive([workflow])
        case .openShortcuts:
          break
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: workflow)
        }
      case .type(let action, _, _):
        switch action {
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
          await groupStore.receive([workflow])
        case .updateSource(let newInput):
          switch command {
          case .type(var typeCommand):
            typeCommand.input = newInput
            command = .type(typeCommand)
          default:
            fatalError("Wrong command type")
          }
          workflow.updateOrAddCommand(command)
          await groupStore.receive([workflow])
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: workflow)
        }
      }
    }
  }

  private func handleCommandContainerAction(_ action: CommandContainerAction,
                                            command: Command,
                                            workflow: Workflow) async {
    switch action {
    case .run:
      break
    case .delete:
      var workflow = workflow
      workflow.commands.removeAll(where: { $0.id == command.id })
      await groupStore.receive([workflow])
    }
  }

  private func render(_ content: [ContentViewModel]) async {
    let ids = content.map(\.id)
    let workflows = groupStore.groups
      .flatMap(\.workflows)
      .filter { ids.contains($0.id) }

    var viewModels: [DetailViewModel] = []
    for workflow in workflows {
      let commands = workflow.commands
        .map { command in
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
            kind = .keyboard(key: keyboardCommand.keyboardShortcut.key,
                             modifiers: keyboardCommand.keyboardShortcut.modifiers ?? [])
            name = command.name
          case .open(let openCommand):
            let appName: String?
            if let app = openCommand.application {
              appName = app.displayName
            } else if let url = URL(string: openCommand.path),
                      let appUrl = NSWorkspace.shared.urlForApplication(toOpen: url),
                      let app = applicationStore.application(at: appUrl) {
              appName = app.displayName
            } else {
              appName = nil
            }

            kind = .open(path: openCommand.path, appName: appName)

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
                let fileExtension = (source as NSString).pathExtension
                kind = .script(.path(id: script.id,
                                     source: source,
                                     fileExtension: fileExtension.uppercased()))
              case .inline(_):
                let type: String
                switch script {
                case .shell:
                  type = "sh"
                case .appleScript:
                  type = "scpt"
                }
                kind = .script(.inline(id: script.id, type: type))
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

      let viewModel = DetailViewModel(
        id: workflow.id,
        name: workflow.name,
        isEnabled: workflow.isEnabled,
        trigger: workflow.trigger?.asViewModel(),
        commands: commands)
      viewModels.append(viewModel)
    }

    let state: DetailViewState
    if viewModels.count > 1 {
      state = .multiple(viewModels)
    } else if let viewModel = viewModels.first {
      state = .single(viewModel)
    } else {
      state = .empty
    }

    await publisher.publish(state)
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

extension Workflow.Trigger {
  func asViewModel() -> DetailViewModel.Trigger {
    switch self {
    case .application(let triggers):
      return .applications(
        triggers.map { trigger in
          DetailViewModel.ApplicationTrigger(id: trigger.id,
                                             name: trigger.application.displayName,
                                             image: NSWorkspace.shared.icon(forFile: trigger.application.path),
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
      let values = shortcuts.map {
        DetailViewModel.KeyboardShortcut(id: $0.id, displayValue: $0.key, modifier: .shift)
      }
      return .keyboardShortcuts(values)
    }
  }
}

extension CommandView.Kind {
  var workflowId: DetailViewModel.ID {
    switch self {
    case .application(_, let workflowId, _),
        .keyboard(_, let workflowId, _),
        .open(_, let workflowId, _),
        .script(_, let workflowId, _),
        .shortcut(_, let workflowId, _),
        .type(_, let workflowId, _):
      return workflowId
    }
  }

  var commandId: DetailViewModel.CommandViewModel.ID {
    switch self {
    case .application(_, _, let commandId),
        .keyboard(_, _, let commandId),
        .open(_, _, let commandId),
        .script(_, _, let commandId),
        .shortcut(_, _, let commandId),
        .type(_, _, let commandId):
      return commandId
    }
  }
}

extension CommandView.Action {
  var workflowId: DetailViewModel.ID {
    switch self {
    case .modify(let kind):
      return kind.workflowId
    case .run(let workflowId, _),
        .remove(let workflowId, _):
      return workflowId
    }
  }

  var commandId: DetailViewModel.CommandViewModel.ID {
    switch self {
    case .modify(let kind):
      return kind.commandId
    case .run(_, let commandId),
        .remove(_, let commandId):
      return commandId
    }
  }

}

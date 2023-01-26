import Apps
import Combine
import SwiftUI

@MainActor
final class DetailCoordinator {
  private var subscription: AnyCancellable?
  private var groupIds: [WorkflowGroup.ID] = []

  let applicationStore: ApplicationStore
  let contentStore: ContentStore
  let keyboardCowboyEngine: KeyboardCowboyEngine
  let groupStore: GroupStore
  let statePublisher: DetailStatePublisher = .init(.empty)
  let detailPublisher: DetailPublisher = .init(DesignTime.detail)
  let mapper: DetailModelMapper

  init(applicationStore: ApplicationStore,
       contentStore: ContentStore,
       keyboardCowboyEngine: KeyboardCowboyEngine,
       groupStore: GroupStore) {
    self.applicationStore = applicationStore
    self.keyboardCowboyEngine = keyboardCowboyEngine
    self.contentStore = contentStore
    self.groupStore = groupStore
    self.mapper = DetailModelMapper(applicationStore)
  }

  func subscribe(to publisher: Published<ContentSelectionIds>.Publisher) {
    subscription = publisher
      .dropFirst()
      .debounce(for: .milliseconds(80), scheduler: DispatchQueue.main)
      .sink { [weak self] ids in
        self?.groupIds = ids.groupIds
        self?.render(ids.workflowIds, groupIds: ids.groupIds)
    }
  }

  func addOrUpdateCommand(_ payload: NewCommandPayload,
                          workflowId: Workflow.ID,
                          title: String,
                          commandId: Command.ID?) {
    Task {
      guard var workflow = groupStore.workflow(withId: workflowId) else { return }
      let command: Command
      let resolvedCommandId: String = commandId ?? UUID().uuidString
      switch payload {
      case .placeholder:
        return
      case .keyboardShortcut(let keyShortcuts):
        command = .keyboard(.init(keyboardShortcuts: keyShortcuts))
      case .script(let value, let kind, let scriptExtension):
        let source: ScriptCommand.Source
        switch kind {
        case .file:
          source = .path(value)
        case .source:
          source = .inline(value)
        }

        switch scriptExtension {
        case .appleScript:
          command = .script(.appleScript(id: resolvedCommandId, isEnabled: true, name: title, source: source))
        case .shellScript:
          command = .script(.shell(id: resolvedCommandId, isEnabled: true, name: title, source: source))
        }
      case .type(let text):
        command = .type(.init(id: resolvedCommandId, name: text, input: text))
      case .shortcut(let name):
        command = .shortcut(.init(id: resolvedCommandId, shortcutIdentifier: name,
                                  name: name, isEnabled: true))
      case .application(let application, let action,
                        let inBackground, let hideWhenRunning, let ifNotRunning):
        assert(application != nil)
        guard let application else {
          return
        }

        var modifiers = [ApplicationCommand.Modifier]()
        if inBackground { modifiers.append(.background) }
        if hideWhenRunning { modifiers.append(.hidden) }
        if ifNotRunning { modifiers.append(.onlyIfNotRunning) }

        let commandAction: ApplicationCommand.Action
        switch action {
        case .close:
          commandAction = .close
        case .open:
          commandAction = .open
        }

        command = Command.application(.init(id: resolvedCommandId,
                                            name: title,
                                            action: commandAction,
                                            application: application,
                                            modifiers: modifiers))
      case .open(let path, let application):
        let resolvedPath = (path as NSString).expandingTildeInPath
        command = Command.open(.init(id: resolvedCommandId, name: "Open \(path)", application: application, path: resolvedPath))
      case .url(let targetUrl, let application):
        let urlString = targetUrl.absoluteString
        command = Command.open(.init(id: resolvedCommandId, name: "Open \(urlString)", application: application, path: urlString))
      }

      workflow.updateOrAddCommand(command)
      groupStore.receive([workflow])
      render([workflow.id], groupIds: groupIds, animation: .easeInOut(duration: 0.2))
    }
  }

  func handle(_ action: DetailView.Action) async {
      switch action {
      case .singleDetailView(let action):
        guard var workflow = groupStore.workflow(withId: action.workflowId) else { return }

        switch action {
        case .updateKeyboardShortcuts(_, let keyboardShortcuts):
          workflow.trigger = .keyboardShortcuts(keyboardShortcuts)
        case .commandView(_, let action):
          await handleCommandAction(action, workflow: &workflow)
        case .moveCommand(_, let fromOffsets, let toOffset):
          workflow.commands.move(fromOffsets: fromOffsets, toOffset: toOffset)
        case .updateName(_, let name):
          workflow.name = name
        case .setIsEnabled(_, let isEnabled):
          workflow.isEnabled = isEnabled
        case .removeCommands(_, let commandIds):
          workflow.commands.removeAll(where: { commandIds.contains($0.id) })
        case .trigger(_, let action):
          switch action {
          case .addKeyboardShortcut:
            workflow.trigger = .keyboardShortcuts([])
          case .removeKeyboardShortcut:
            Swift.print("Remove keyboard shortcut")
          case .addApplication:
            workflow.trigger = .application([])
          }
        case .removeTrigger(_):
          workflow.trigger = nil
        case .applicationTrigger(_, let action):
          switch action {
          case .updateApplicationTriggers(let triggers):
            let applicationTriggers = triggers
              .map { viewModelTrigger in
                var contexts = Set<ApplicationTrigger.Context>()
                if viewModelTrigger.contexts.contains(.closed) {
                  contexts.insert(.closed)
                } else {
                  contexts.remove(.closed)
                }

                if viewModelTrigger.contexts.contains(.frontMost) {
                  contexts.insert(.frontMost)
                } else {
                  contexts.remove(.frontMost)
                }

                if viewModelTrigger.contexts.contains(.launched) {
                  contexts.insert(.launched)
                } else {
                  contexts.remove(.launched)
                }

                return ApplicationTrigger(id: viewModelTrigger.id,
                                   application: viewModelTrigger.application,
                                   contexts: Array(contexts))
              }
            workflow.trigger = .application(applicationTriggers)
          case .updateApplicationTriggerContext(let viewModelTrigger):
            if case .application(var previousTriggers) = workflow.trigger,
               let index = previousTriggers.firstIndex(where: { $0.id == viewModelTrigger.id }) {
              var newTrigger = previousTriggers[index]

              if viewModelTrigger.contexts.contains(.closed) {
                newTrigger.contexts.insert(.closed)
              } else {
                newTrigger.contexts.remove(.closed)
              }

              if viewModelTrigger.contexts.contains(.frontMost) {
                newTrigger.contexts.insert(.frontMost)
              } else {
                newTrigger.contexts.remove(.frontMost)
              }

              if viewModelTrigger.contexts.contains(.launched) {
                newTrigger.contexts.insert(.launched)
              } else {
                newTrigger.contexts.remove(.launched)
              }

              previousTriggers[index] = newTrigger
              workflow.trigger = .application(previousTriggers)
            }
          }
        }

        groupStore.receive([workflow])
        render([workflow.id], groupIds: groupIds, animation: .easeInOut(duration: 0.2))
    }
  }

  func handleCommandAction(_ commandAction: CommandView.Action, workflow: inout Workflow) async {
    guard var command: Command = workflow.commands.first(where: { $0.id == commandAction.commandId }) else {
      fatalError("Unable to find command.")
    }

    switch commandAction {
    case .toggleEnabled(_, _, let newValue):
      command.isEnabled = newValue
      workflow.updateOrAddCommand(command)
    case .run(_, _):
      break
    case .remove(_, let commandId):
      workflow.commands.removeAll(where: { $0.id == commandId })
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
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
        case .changeApplicationAction(let action):
          switch action {
          case .open:
            applicationCommand.action = .open
          case .close:
            applicationCommand.action = .close
          }
          command = .application(applicationCommand)
          workflow.updateOrAddCommand(command)
        case .changeApplicationModifier(let modifier, let newValue):
          if newValue {
            applicationCommand.modifiers.insert(modifier)
          } else {
            applicationCommand.modifiers.remove(modifier)
          }
          command = .application(applicationCommand)
          workflow.updateOrAddCommand(command)
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: &workflow)
        }
      case .keyboard(let action, _, _):
        switch action {
        case .updateKeyboardShortcuts(let keyboardShortcuts):
          command = .keyboard(.init(id: command.id, keyboardShortcuts: keyboardShortcuts))
          workflow.updateOrAddCommand(command)
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: &workflow)
        }
      case .open(let action, _, _):
        switch action {
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
        case .openWith:
          break
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: &workflow)
        case .reveal(let path):
          NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }
      case .script(let action, _, _):
        switch action {
        case .updateSource(let newKind):
          let scriptCommand: ScriptCommand
          switch newKind {
          case .path(let id, let source, let kind):
            switch kind {
            case .shellScript:
              scriptCommand = .shell(id: id, isEnabled: command.isEnabled, name: command.name, source: .path(source))
            case .appleScript:
              scriptCommand = .appleScript(id: id, isEnabled: command.isEnabled, name: command.name, source: .path(source))
            }
          case .inline(let id, let source, let kind):
            switch kind {
            case .shellScript:
              scriptCommand = .shell(id: id, isEnabled: command.isEnabled, name: command.name, source: .inline(source))
            case .appleScript:
              scriptCommand = .appleScript(id: id, isEnabled: command.isEnabled, name: command.name, source: .inline(source))
            }
          }
          command = .script(scriptCommand)
          workflow.updateOrAddCommand(command)
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
        case .open(let source):
          Task {
            let path = (source as NSString).expandingTildeInPath
            keyboardCowboyEngine.run([
              .open(.init(path: path))
            ], serial: true)
          }
        case .reveal(let path):
          NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        case .edit:
          break
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: &workflow)
        }
      case .shortcut(let action, _, _):
        switch action {
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
        case .openShortcuts:
          break
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: &workflow)
        }
      case .type(let action, _, _):
        switch action {
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
        case .updateSource(let newInput):
          switch command {
          case .type(var typeCommand):
            typeCommand.input = newInput
            command = .type(typeCommand)
          default:
            fatalError("Wrong command type")
          }
          workflow.updateOrAddCommand(command)
        case .commandAction(let action):
          await handleCommandContainerAction(action, command: command, workflow: &workflow)
        }
      }
    }
  }

  private func handleCommandContainerAction(_ action: CommandContainerAction,
                                            command: Command,
                                            workflow: inout Workflow) async {
    switch action {
    case .run:
      break
    case .delete:
      workflow.commands.removeAll(where: { $0.id == command.id })
    }
  }

  @MainActor
  private func render(_ ids: [Workflow.ID], groupIds: [WorkflowGroup.ID], animation: Animation? = nil) {
    let workflows = groupStore.groups
      .filter({ groupIds.contains($0.id) })
      .flatMap(\.workflows)
      .filter { ids.contains($0.id) }

    let viewModels: [DetailViewModel] = mapper.map(workflows)
    let state: DetailViewState

    if viewModels.count > 1 {
      state = .multiple(viewModels)
    } else if let viewModel = viewModels.first {
      state = .single

      if let animation {
        withAnimation(animation) {
          detailPublisher.publish(viewModel)
        }
      } else {
        detailPublisher.publish(viewModel)
      }
    } else {
      state = .empty
    }

    if let animation {
      withAnimation(animation) {
        statePublisher.publish(state)
      }
    } else {
      statePublisher.publish(state)
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
    case .toggleEnabled(let workflowId, _, _):
      return workflowId
    case .modify(let kind):
      return kind.workflowId
    case .run(let workflowId, _),
        .remove(let workflowId, _):
      return workflowId
    }
  }

  var commandId: DetailViewModel.CommandViewModel.ID {
    switch self {
    case .toggleEnabled(_, let commandId, _):
      return commandId
    case .modify(let kind):
      return kind.commandId
    case .run(_, let commandId),
        .remove(_, let commandId):
      return commandId
    }
  }
}

extension SingleDetailView.Action {
  var workflowId: String {
    switch self {
    case .updateKeyboardShortcuts(let workflowId, _):
      return workflowId
    case .removeTrigger(let workflowId):
      return workflowId
    case .setIsEnabled(let workflowId, _):
      return workflowId
    case .removeCommands(let workflowId, _):
      return workflowId
    case .applicationTrigger(let workflowId, _):
      return workflowId
    case .commandView(let workflowId, _):
      return workflowId
    case .moveCommand(let workflowId, _, _):
      return workflowId
    case .trigger(let workflowId, _):
      return workflowId
    case .updateName(let workflowId, _):
      return workflowId
    }
  }
}

import Apps
import Combine
import SwiftUI

@MainActor
final class DetailCoordinator {
  static private var appStorage: AppStorageStore = .init()
  private var subscription: AnyCancellable?
  private var groupIds: [WorkflowGroup.ID] = []

  let applicationStore: ApplicationStore
  let commandEngine: CommandEngine
  let contentStore: ContentStore
  let keyboardCowboyEngine: KeyboardCowboyEngine
  let groupStore: GroupStore
  let statePublisher: DetailStatePublisher = .init(.empty)
  let detailPublisher: DetailPublisher = .init(DesignTime.emptyDetail)
  let mapper: DetailModelMapper

  init(applicationStore: ApplicationStore,
       commandEngine: CommandEngine,
       contentStore: ContentStore,
       keyboardCowboyEngine: KeyboardCowboyEngine,
       groupStore: GroupStore) {
    self.applicationStore = applicationStore
    self.keyboardCowboyEngine = keyboardCowboyEngine
    self.commandEngine = commandEngine
    self.contentStore = contentStore
    self.groupStore = groupStore
    self.mapper = DetailModelMapper(applicationStore)

    enableInjection(self, selector: #selector(injected(_:)))
  }

  func subscribe(to publisher: Published<ContentSelectionIds>.Publisher) {
    subscription = publisher
      .debounce(for: .milliseconds(40), scheduler: RunLoop.main)
      .dropFirst()
      .removeDuplicates()
      .sink { [weak self] ids in
        self?.groupIds = ids.groupIds
        self?.render(ids.workflowIds, groupIds: ids.groupIds)
    }
  }

  // TODO: Add support for `.notification` when adding new commands
  // - Maybe we should add it to `NewCommandPayload`
  func addOrUpdateCommand(_ payload: NewCommandPayload, workflowId: Workflow.ID,
                          title: String, commandId: Command.ID?) async {
    guard var workflow = groupStore.workflow(withId: workflowId) else { return }
    let command: Command
    let resolvedCommandId: String = commandId ?? UUID().uuidString
    switch payload {
    case .placeholder:
      return
    case .keyboardShortcut(let keyShortcuts):
      command = .keyboard(.init(keyboardShortcuts: keyShortcuts, notification: false))
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
      // TODO: Add support for notification toggling
      command = .type(.init(id: resolvedCommandId, name: text, input: text, notification: false))
    case .shortcut(let name):
      command = .shortcut(.init(id: resolvedCommandId, shortcutIdentifier: name,
                                name: name, isEnabled: true, notification: false))
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
                                          modifiers: modifiers,
                                          notification: false))
    case .open(let path, let application):
      let resolvedPath = (path as NSString).expandingTildeInPath
      command = Command.open(.init(id: resolvedCommandId,
                                   name: "Open \(path)", application: application, path: resolvedPath,
                                   notification: false))
    case .url(let targetUrl, let application):
      let urlString = targetUrl.absoluteString
      command = Command.open(.init(id: resolvedCommandId,
                                   name: "Open \(urlString)", application: application, path: urlString,
                                   notification: false))
    case .systemCommand(let kind):
      command = Command.systemCommand(.init(id: UUID().uuidString,
                                            name: "System command",
                                            kind: kind,
                                            notification: false))
    }

    workflow.updateOrAddCommand(command)
    await groupStore.commit([workflow])
    render([workflow.id], groupIds: groupIds, animation: .easeInOut(duration: 0.2))
  }

  func handle(_ detailAction: DetailView.Action) {
    switch detailAction {
    case .singleDetailView(let action):
      guard var workflow = groupStore.workflow(withId: action.workflowId) else { return }
      let shouldCallRender = DetailViewActionReducer.reduce(detailAction,
                                                            commandEngine: commandEngine,
                                                            keyboardCowboyEngine: keyboardCowboyEngine,
                                                            applicationStore: applicationStore,
                                                            workflow: &workflow)
      groupStore.commit([workflow])

      if shouldCallRender {
        render([workflow.id], groupIds: groupIds)
      }
    }
  }

  // MARK: Private methods

  @objc private func injected(_ notification: Notification) {
    guard didInject(self, notification: notification) else { return }
    withAnimation(.easeInOut(duration: 0.2)) {
      render(Array(Self.appStorage.workflowIds),
             groupIds: Array(Self.appStorage.groupIds),
             animation: .default)
    }
  }

  private func render(_ ids: [Workflow.ID], groupIds: [WorkflowGroup.ID], animation: Animation? = nil) {
    Benchmark.start("DetailCoordinator.render")
    defer {
      Benchmark.finish("DetailCoordinator.render")
    }
    let workflows = groupStore.groups
      .filter { groupIds.contains($0.id) }
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

extension DetailView.Action {
  var workflowId: String? {
    switch self {
    case .singleDetailView(let action):
      return action.workflowId
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
    case .dropUrls(let workflowId, _):
      return workflowId
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
    case .updateExecution(let workflowId, _):
      return workflowId
    case .runWorkflow(let workflowId):
      return workflowId
    }
  }
}

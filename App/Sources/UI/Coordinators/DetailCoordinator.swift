import Apps
import Combine
import SwiftUI

@MainActor
final class DetailCoordinator {
  private let applicationStore: ApplicationStore
  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandRunner: CommandRunner
  private let commandSelectionManager: SelectionManager<CommandViewModel>
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let contentStore: ContentStore
  private let groupSelectionManager: SelectionManager<GroupViewModel>
  private let groupStore: GroupStore
  private let keyboardCowboyEngine: KeyboardCowboyEngine
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>

  let infoPublisher: InfoPublisher = .init(.init(id: "empty", name: "", isEnabled: false))
  let triggerPublisher: TriggerPublisher = .init(.empty)
  let commandsPublisher: CommandsPublisher = .init(.init(id: "empty", commands: [], execution: .concurrent))

  let mapper: DetailModelMapper
  let statePublisher: DetailStatePublisher = .init(.empty)

  init(applicationStore: ApplicationStore,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandRunner: CommandRunner,
       commandSelectionManager: SelectionManager<CommandViewModel>,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       contentStore: ContentStore,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       keyboardCowboyEngine: KeyboardCowboyEngine,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       groupStore: GroupStore) {
    self.applicationStore = applicationStore
    self.commandRunner = commandRunner
    self.commandSelectionManager = commandSelectionManager
    self.contentSelectionManager = contentSelectionManager
    self.contentStore = contentStore
    self.groupSelectionManager = groupSelectionManager
    self.groupStore = groupStore
    self.keyboardCowboyEngine = keyboardCowboyEngine
    self.mapper = DetailModelMapper(applicationStore)
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager

    enableInjection(self, selector: #selector(injected(_:)))
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .refresh, .updateConfiguration, .openScene, .addConfiguration, .deleteConfiguraiton:
      // NOOP
      break
    case .moveWorkflows, .copyWorkflows:
      render(contentSelectionManager.selections,
             groupIds: groupSelectionManager.selections)
    case .moveGroups, .removeGroups:
      render(contentSelectionManager.selections,
             groupIds: groupSelectionManager.selections)
    case .selectConfiguration:
      render(contentSelectionManager.selections,
             groupIds: groupSelectionManager.selections)
    case .selectGroups(let ids):
      if let firstId = ids.first,
         let group = groupStore.group(withId: firstId) {
        var workflowIds = Set<ContentViewModel.ID>()

        let nsColor = NSColor(hex: group.color).blended(withFraction: 0.4, of: .black) ?? .controlAccentColor
        applicationTriggerSelectionManager.selectedColor = Color(nsColor: nsColor)
        keyboardShortcutSelectionManager.selectedColor = Color(nsColor: nsColor)
        commandSelectionManager.selectedColor = Color(nsColor: nsColor)

        let matches = group.workflows.filter { contentSelectionManager.selections.contains($0.id) }
          .map(\.id)

        if !matches.isEmpty {
          workflowIds = Set(matches)
        } else if let firstId = group.workflows.first?.id {
          workflowIds.insert(firstId)
        }
        render(workflowIds, groupIds: Set(ids))

        applicationTriggerSelectionManager.removeLastSelection()
        keyboardShortcutSelectionManager.removeLastSelection()
        commandSelectionManager.removeLastSelection()
      }
    }
  }

  func handle(_ action: ContentListView.Action) {
    switch action {
    case .refresh, .moveWorkflowsToGroup, .reorderWorkflows, .duplicate:
      return
    case .selectWorkflow(let workflowIds, let groupIds):
      render(workflowIds, groupIds: groupIds)
    case .removeWorkflows:
      guard let first = groupSelectionManager.selections.first,
            let group = groupStore.group(withId: first) else {
        return
      }
      if group.workflows.isEmpty {
        render([], groupIds: groupSelectionManager.selections)
      }
    case .addWorkflow(let workflowId):
      render([workflowId], groupIds: groupSelectionManager.selections)
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
    case .menuBar(let tokens):
      command = .menuBar(.init(id: resolvedCommandId, tokens: tokens))
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
        command = .script(.init(name: title, kind: .appleScript, source: source, notification: false))
      case .shellScript:
        command = .script(.init(name: title, kind: .shellScript, source: source, notification: false))
      }
    case .type(let text, let mode):
      // TODO: Add support for notification toggling
      command = .type(.init(id: resolvedCommandId, name: text, mode: mode, input: text, notification: false))
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
                                   name: "\(path)", application: application, path: resolvedPath,
                                   notification: false))
    case .url(let targetUrl, let application):
      let urlString = targetUrl.absoluteString
      command = Command.open(.init(id: resolvedCommandId,
                                   name: "\(urlString)", application: application, path: urlString,
                                   notification: false))
    case .systemCommand(let kind):
      command = Command.systemCommand(.init(id: UUID().uuidString,
                                            name: "System command",
                                            kind: kind,
                                            notification: false))
    case .windowManagement(let kind):
      command = Command.windowManagement(.init(id: UUID().uuidString,
                                               name: "Window Management Command",
                                               kind: kind,
                                               notification: false,
                                               animationDuration: 0))
    }

    workflow.updateOrAddCommand(command)
    await groupStore.commit([workflow])
    render([workflow.id], groupIds: groupSelectionManager.selections,
           animation: .easeInOut(duration: 0.2))
  }

  func handle(_ detailAction: DetailView.Action) {
    switch detailAction {
    case .singleDetailView(let action):
      guard var workflow = groupStore.workflow(withId: action.workflowId) else { return }
      let result = DetailViewActionReducer.reduce(
        detailAction,
        commandRunner: commandRunner,
        selectionManager: commandSelectionManager,
        keyboardCowboyEngine: keyboardCowboyEngine,
        applicationStore: applicationStore,
        workflow: &workflow)
      
      groupStore.commit([workflow])

      switch result {
      case .animated(let animation):
        withAnimation(animation) {
          render([workflow.id], groupIds: groupSelectionManager.selections)
        }
      case .refresh:
        render([workflow.id], groupIds: groupSelectionManager.selections)
      case .none:
        break
      }
    }
  }

  // MARK: Private methods

  @objc private func injected(_ notification: Notification) {
    guard didInject(self, notification: notification) else { return }
    withAnimation(.easeInOut(duration: 0.2)) {
      render(contentSelectionManager.selections,
             groupIds: groupSelectionManager.selections,
             animation: .default)
    }
  }

  private func render(_ ids: Set<Workflow.ID>, groupIds: Set<WorkflowGroup.ID>, animation: Animation? = nil) {
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

      withAnimation(animation) {
        infoPublisher.publish(viewModel.info)
        triggerPublisher.publish(viewModel.trigger)
        commandsPublisher.publish(.init(id: viewModel.id,
                                        commands: viewModel.commandsInfo.commands,
                                        execution: viewModel.commandsInfo.execution))
      }
    } else {
      state = .empty
    }

    guard statePublisher.data != state else { return }

    if let animation {
      withAnimation(animation) {
        statePublisher.publish(state)
      }
    } else {
      statePublisher.publish(state)
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
        .type(_, let workflowId, _),
        .system(_, let workflowId, _),
        .window(_, let workflowId, _):
      return workflowId
    }
  }

  var commandId: CommandViewModel.ID {
    switch self {
    case .application(_, _, let commandId),
        .keyboard(_, _, let commandId),
        .open(_, _, let commandId),
        .script(_, _, let commandId),
        .shortcut(_, _, let commandId),
        .type(_, _, let commandId),
        .system(_, _, let commandId),
        .window(_, _, let commandId):
      return commandId
    }
  }
}

extension CommandView.Action {
  var commandId: CommandViewModel.ID {
    switch self {
    case .toggleEnabled(_, let commandId, _),
         .toggleNotify(_, let commandId, _),
         .changeDelay(_, let commandId, _):
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
    case .dropUrls(let workflowId, _),
         .duplicate(let workflowId, _),
         .updateKeyboardShortcuts(let workflowId, _, _, _),
         .removeTrigger(let workflowId),
         .setIsEnabled(let workflowId, _),
         .removeCommands(let workflowId, _),
         .applicationTrigger(let workflowId, _),
         .commandView(let workflowId, _),
         .moveCommand(let workflowId, _, _),
         .trigger(let workflowId, _),
         .updateName(let workflowId, _),
         .updateExecution(let workflowId, _),
         .runWorkflow(let workflowId),
         .togglePassthrough(let workflowId, _),
         .updateHoldDuration(let workflowId, _):
      return workflowId
    }
  }
}

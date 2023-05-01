import Apps
import Combine
import SwiftUI

@MainActor
final class DetailCoordinator {
  let applicationStore: ApplicationStore
  let commandEngine: CommandEngine
  let contentSelectionManager: SelectionManager<ContentViewModel>
  let contentStore: ContentStore
  let detailPublisher: DetailPublisher = .init(DesignTime.emptyDetail)
  let groupSelectionManager: SelectionManager<GroupViewModel>
  let groupStore: GroupStore
  let keyboardCowboyEngine: KeyboardCowboyEngine
  let mapper: DetailModelMapper
  let statePublisher: DetailStatePublisher = .init(.empty)

  init(applicationStore: ApplicationStore,
       commandEngine: CommandEngine,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       contentStore: ContentStore,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       keyboardCowboyEngine: KeyboardCowboyEngine,
       groupStore: GroupStore) {
    self.applicationStore = applicationStore
    self.commandEngine = commandEngine
    self.contentSelectionManager = contentSelectionManager
    self.contentStore = contentStore
    self.groupSelectionManager = groupSelectionManager
    self.groupStore = groupStore
    self.keyboardCowboyEngine = keyboardCowboyEngine
    self.mapper = DetailModelMapper(applicationStore)

    enableInjection(self, selector: #selector(injected(_:)))
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .moveWorkflows, .copyWorkflows:
      render(contentSelectionManager.selections,
             groupIds: groupSelectionManager.selections)
    case .openScene:
      break
    case .addConfiguration:
      break
    case .selectConfiguration:
      break
    case .selectGroups(let array):
      if let firstId = array.first,
         let group = groupStore.group(withId: firstId) {
        var workflowIds = Set<ContentViewModel.ID>()

        let matches = group.workflows.filter { contentSelectionManager.selections.contains($0.id) }
          .map(\.id)

        if !matches.isEmpty {
          workflowIds = Set(matches)
        } else if let firstId = group.workflows.first?.id {
          workflowIds.insert(firstId)
        }
        render(workflowIds, groupIds: Set(array))
      }
    case .moveGroups:
      break
    case .removeGroups:
      break
    }
  }

  func handle(_ action: ContentView.Action) {
    switch action {
    case .rerender:
      return
    case .moveWorkflowsToGroup:
      return
    case .selectWorkflow(let workflowIds, let groupIds):
      render(workflowIds, groupIds: groupIds)
    case .removeWorflows:
      guard let first = groupSelectionManager.selections.first,
            let group = groupStore.group(withId: first) else {
        return
      }
      if group.workflows.isEmpty {
        render([], groupIds: groupSelectionManager.selections)
      }
    case .moveWorkflows:
      return
    case .addWorkflow(let workflowId):
      render([workflowId], groupIds: groupSelectionManager.selections)
    case .addCommands:
      return
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
    render([workflow.id], groupIds: groupSelectionManager.selections,
           animation: .easeInOut(duration: 0.2))
  }

  func handle(_ detailAction: DetailView.Action) {
    switch detailAction {
    case .singleDetailView(let action):
      guard var workflow = groupStore.workflow(withId: action.workflowId) else { return }
      let result = DetailViewActionReducer.reduce(detailAction,
                                                  commandEngine: commandEngine,
                                                  keyboardCowboyEngine: keyboardCowboyEngine,
                                                  applicationStore: applicationStore,
                                                  workflow: &workflow)
      groupStore.commit([workflow])

      switch result {
      case .animated:
        withAnimation(.default) {
          render([workflow.id], groupIds: groupSelectionManager.selections)
        }
      case .rerender:
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


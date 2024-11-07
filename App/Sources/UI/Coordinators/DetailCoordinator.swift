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

  let updateTransaction: UpdateTransaction = .init(groupID: "", workflowID: "")
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
    case .addConfiguration:
      render(contentSelectionManager.selections,
             groupIds: groupSelectionManager.selections)
    case .refresh, .updateConfiguration, .openScene, .deleteConfiguration, .userMode:
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

  func handle(_ action: ContentView.Action) {
    switch action {
    case .refresh, .moveWorkflowsToGroup, .reorderWorkflows, .duplicate:
      return
    case .moveCommandsToWorkflow(_, let workflowId, _):
      guard let groupId = groupSelectionManager.selections.first else { return }
      render([workflowId], groupIds: [groupId])
    case .selectWorkflow(let workflowIds):
      render(workflowIds, groupIds: groupSelectionManager.selections)
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
    Benchmark.shared.start("DetailCoordinator.render")
    defer {
      Benchmark.shared.stop("DetailCoordinator.render")
    }
    let workflows = groupStore.groups
      .filter { groupIds.contains($0.id) }
      .flatMap(\.workflows)
    let matches = workflows
      .filter { ids.contains($0.id) }
    let viewModels: [DetailViewModel] = mapper.map(matches)
    let state: DetailViewState

    updateTransaction.groupID = groupIds.first ?? ""

    if viewModels.count > 1 {
      state = .multiple(viewModels)
    } else if let viewModel = viewModels.first {
      state = .single(viewModel)

      updateTransaction.workflowID = viewModel.id

      // Only use `withAnimation` if `animation` is not `nil` to
      // prevent the application from crashing when performing certain updates.
      if let animation {
        withAnimation(animation) {
          infoPublisher.publish(viewModel.info)
          triggerPublisher.publish(viewModel.trigger)
          commandsPublisher.publish(.init(id: viewModel.id,
                                          commands: viewModel.commandsInfo.commands,
                                          execution: viewModel.commandsInfo.execution))
        }
      } else {
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

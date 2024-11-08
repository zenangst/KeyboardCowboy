import Apps
import Combine
import SwiftUI

@MainActor
final class WorkflowCoordinator {
  private let applicationStore: ApplicationStore
  private let applicationTriggerSelection: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandRunner: CommandRunner
  private let commandSelection: SelectionManager<CommandViewModel>
  private let workflowsSelection: SelectionManager<GroupDetailViewModel>
  private let contentStore: ContentStore
  private let groupSelection: SelectionManager<GroupViewModel>
  private let groupStore: GroupStore
  private let keyboardCowboyEngine: KeyboardCowboyEngine
  private let keyboardShortcutSelection: SelectionManager<KeyShortcut>

  let updateTransaction: UpdateTransaction = .init(groupID: "", workflowID: "")
  let infoPublisher: InfoPublisher = .init(.init(id: "empty", name: "", isEnabled: false))
  let triggerPublisher: TriggerPublisher = .init(.empty)
  let commandsPublisher: CommandsPublisher = .init(.init(id: "empty", commands: [], execution: .concurrent))

  let mapper: DetailModelMapper
  let statePublisher: DetailStatePublisher = .init(.empty)

  init(applicationStore: ApplicationStore,
       applicationTriggerSelection: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandRunner: CommandRunner,
       commandSelection: SelectionManager<CommandViewModel>,
       workflowsSelection: SelectionManager<GroupDetailViewModel>,
       contentStore: ContentStore,
       groupSelection: SelectionManager<GroupViewModel>,
       keyboardCowboyEngine: KeyboardCowboyEngine,
       keyboardShortcutSelection: SelectionManager<KeyShortcut>,
       groupStore: GroupStore) {
    self.applicationStore = applicationStore
    self.commandRunner = commandRunner
    self.commandSelection = commandSelection
    self.workflowsSelection = workflowsSelection
    self.contentStore = contentStore
    self.groupSelection = groupSelection
    self.groupStore = groupStore
    self.keyboardCowboyEngine = keyboardCowboyEngine
    self.mapper = DetailModelMapper(applicationStore)
    self.keyboardShortcutSelection = keyboardShortcutSelection
    self.applicationTriggerSelection = applicationTriggerSelection

    enableInjection(self, selector: #selector(injected(_:)))
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .addConfiguration:
      render(workflowsSelection.selections,
             groupIds: groupSelection.selections)
    case .refresh, .updateConfiguration, .openScene, .deleteConfiguration, .userMode:
      // NOOP
      break
    case .moveWorkflows, .copyWorkflows:
      render(workflowsSelection.selections,
             groupIds: groupSelection.selections)
    case .moveGroups, .removeGroups:
      render(workflowsSelection.selections,
             groupIds: groupSelection.selections)
    case .selectConfiguration:
      render(workflowsSelection.selections,
             groupIds: groupSelection.selections)
    case .selectGroups(let ids):
      if let firstId = ids.first,
         let group = groupStore.group(withId: firstId) {
        var workflowIds = Set<GroupDetailViewModel.ID>()

        let matches = group.workflows.filter { workflowsSelection.selections.contains($0.id) }
          .map(\.id)

        if !matches.isEmpty {
          workflowIds = Set(matches)
        } else if let firstId = group.workflows.first?.id {
          workflowIds.insert(firstId)
        }
        render(workflowIds, groupIds: Set(ids))

        applicationTriggerSelection.removeLastSelection()
        keyboardShortcutSelection.removeLastSelection()
        commandSelection.removeLastSelection()
      }
    }
  }

  func handle(_ action: GroupDetailView.Action) {
    switch action {
    case .refresh, .moveWorkflowsToGroup, .reorderWorkflows, .duplicate:
      return
    case .moveCommandsToWorkflow(_, let workflowId, _):
      guard let groupId = groupSelection.selections.first else { return }
      render([workflowId], groupIds: [groupId])
    case .selectWorkflow(let workflowIds):
      render(workflowIds, groupIds: groupSelection.selections)
    case .removeWorkflows:
      guard let first = groupSelection.selections.first,
            let group = groupStore.group(withId: first) else {
        return
      }
      if group.workflows.isEmpty {
        render([], groupIds: groupSelection.selections)
      }
    case .addWorkflow(let workflowId):
      render([workflowId], groupIds: groupSelection.selections)
    }
  }

  // MARK: Private methods

  @objc private func injected(_ notification: Notification) {
    guard didInject(self, notification: notification) else { return }
    withAnimation(.easeInOut(duration: 0.2)) {
      render(workflowsSelection.selections,
             groupIds: groupSelection.selections,
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

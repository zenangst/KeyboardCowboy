import Bonzai
import Combine
import SwiftUI

@MainActor
final class GroupCoordinator {
  private let applicationStore: ApplicationStore
  private let groupSelectionManager: SelectionManager<GroupViewModel>
  private let workflowsSelectionManager: SelectionManager<GroupDetailViewModel>
  private let mapper: GroupDetailViewModelMapper
  private let store: GroupStore

  let groupPublisher: GroupPublisher = .init(
    .init(id: UUID().uuidString, name: "", icon: nil,
          color: "", symbol: "", bundleIdentifiers: [], userModes: [],
          count: 0, isDisabled: false),
  )
  let contentPublisher: GroupDetailPublisher = .init()

  init(_ store: GroupStore,
       applicationStore: ApplicationStore,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       workflowsSelectionManager: SelectionManager<GroupDetailViewModel>) {
    self.applicationStore = applicationStore
    self.store = store
    self.groupSelectionManager = groupSelectionManager
    mapper = GroupDetailViewModelMapper()
    self.workflowsSelectionManager = workflowsSelectionManager
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .refresh, .openScene, .addConfiguration, .updateConfiguration,
         .moveGroups, .removeGroups, .deleteConfiguration, .userMode:
      // NOOP
      break
    case .moveWorkflows, .copyWorkflows:
      render(groupSelectionManager.selections)
    case .selectConfiguration:
      render(groupSelectionManager.selections, calculateSelections: true)
    case let .selectGroups(ids):
      if let id = ids.first,
         let firstGroup = store.group(withId: id) {
        let group = SidebarMapper.map(firstGroup, applicationStore: applicationStore)
        groupPublisher.publish(group)
      }

      let shouldRemoveLastSelection = !contentPublisher.data.isEmpty
      handle(.refresh(ids))

      if shouldRemoveLastSelection, ids.count == 1, ids.first != groupPublisher.data.id {
        if let firstId = contentPublisher.data.first?.id {
          workflowsSelectionManager.setLastSelection(firstId)
        } else {
          workflowsSelectionManager.removeLastSelection()
        }
      } else if let lastSelection = workflowsSelectionManager.lastSelection {
        // Check for invalid selections, reset the last selection to the first one.
        // Otherwise, the focus updates won't work properly because it is looking for an
        // identifier that does not exist in the current group.
        if !contentPublisher.data.contains(where: { $0.id == lastSelection }) {
          if let firstId = contentPublisher.data.first?.id {
            workflowsSelectionManager.setLastSelection(firstId)
          }
        }
      }
    }
  }

  func handle(_ context: EditWorfklowGroupView.Context) {
    switch context {
    case let .add(workflowGroup):
      render([workflowGroup.id])
    case let .edit(workflowGroup):
      let workflowGroup = SidebarMapper.map(workflowGroup, applicationStore: applicationStore)
      groupPublisher.publish(workflowGroup)
      render([workflowGroup.id])
    }
  }

  func handle(_ action: GroupDetailView.Action) {
    // TODO: We should get rid of this guard.
    guard let id = groupSelectionManager.selections.first,
          var group = store.group(withId: id) else { return }

    GroupDetailViewActionReducer.reduce(
      action,
      groupStore: store,
      selectionManager: workflowsSelectionManager,
      group: &group,
    )

    switch action {
    case let .addWorkflow(id):
      store.updateGroups([group])
      withAnimation {
        render([group.id], selectionOverrides: [id])
      }
      NotificationCenter.default.post(.newWorkflow)
    case .selectWorkflow:
      break
    case let .refresh(ids):
      render(ids, calculateSelections: true)
    default:
      store.updateGroups([group])
      render([group.id], calculateSelections: true)
    }
  }

  // MARK: Private methods

  private func render(_ groupIds: Set<GroupViewModel.ID>,
                      calculateSelections: Bool = false,
                      selectionOverrides: Set<Workflow.ID>? = nil) {
    Benchmark.shared.start("ContentCoordinator.render")
    defer { Benchmark.shared.stop("ContentCoordinator.render") }

    var viewModels = [GroupDetailViewModel]()
    var newSelections = Set<GroupDetailViewModel.ID>()
    var selectedWorkflowIds = workflowsSelectionManager.selections
    var firstViewModel: GroupDetailViewModel?

    for offset in store.groups.indices {
      let group = store.groups[offset]
      if groupIds.contains(group.id) {
        for wOffset in group.workflows.indices {
          let workflow = group.workflows[wOffset]
          let viewModel = mapper.map(workflow, groupId: group.id)

          if wOffset == 0 {
            firstViewModel = viewModel
          }

          viewModels.append(viewModel)

          if calculateSelections,
             !selectedWorkflowIds.isEmpty,
             selectedWorkflowIds.contains(viewModel.id) {
            selectedWorkflowIds.remove(viewModel.id)
            newSelections.insert(viewModel.id)
          }
        }
      }
    }

    contentPublisher.publish(viewModels)

    if calculateSelections {
      if contentPublisher.data.isEmpty {
        if newSelections.isEmpty, let first = viewModels.first {
          newSelections = [first.id]
        }
      } else if !workflowsSelectionManager.selections.intersection(viewModels.map(\.id)).isEmpty {
        newSelections = workflowsSelectionManager.selections
      } else if newSelections.isEmpty, let first = firstViewModel {
        newSelections = [first.id]
      }
      workflowsSelectionManager.publish(newSelections)
    } else if let selectionOverrides {
      workflowsSelectionManager.publish(selectionOverrides)
      if let first = selectionOverrides.first {
        workflowsSelectionManager.setLastSelection(first)
      }
    }
  }
}

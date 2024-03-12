import Bonzai
import Combine
import SwiftUI

@MainActor
final class ContentCoordinator {
  private let applicationStore: ApplicationStore
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let groupSelectionManager: SelectionManager<GroupViewModel>
  private let mapper: ContentModelMapper
  private let store: GroupStore

  let groupPublisher: GroupPublisher = GroupPublisher(
    .init(id: UUID().uuidString, name: "", icon: nil,
      color: "", symbol: "", userModes: [], count: 0)
  )
  let contentPublisher: ContentPublisher = ContentPublisher()

  init(_ store: GroupStore,
       applicationStore: ApplicationStore,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>) {
    self.applicationStore = applicationStore
    self.store = store
    self.groupSelectionManager = groupSelectionManager
    self.mapper = ContentModelMapper()
    self.contentSelectionManager = contentSelectionManager

    // Set initial selection
    if let initialGroupSelection = groupSelectionManager.lastSelection,
      let initialWorkflowSelection = contentSelectionManager.lastSelection {
      render([initialGroupSelection], selectionOverrides: [initialWorkflowSelection])
    }
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
    case .selectGroups(let ids):
      if let id = ids.first,
         let firstGroup = store.group(withId: id) {
        let group = SidebarMapper.map(firstGroup, applicationStore: applicationStore)
        groupPublisher.publish(group)
      }

      let shouldRemoveLastSelection = !contentPublisher.data.isEmpty
      handle(.refresh(ids))
      if shouldRemoveLastSelection {
        if let firstId = contentPublisher.data.first?.id {
          contentSelectionManager.setLastSelection(firstId)
        } else {
          contentSelectionManager.removeLastSelection()
        }
      } else if let lastSelection = contentSelectionManager.lastSelection {
        // Check for invalid selections, reset the last selection to the first one.
        // Otherwise, the focus updates won't work properly because it is looking for an
        // identifier that does not exist in the current group.
        if !contentPublisher.data.contains(where: { $0.id == lastSelection }) {
          if let firstId = contentPublisher.data.first?.id {
            contentSelectionManager.setLastSelection(firstId)
          }
        }
      }
    }
  }

  func handle(_ context: EditWorkflowGroupWindow.Context) {
    switch context {
    case .add(let workflowGroup):
      render([workflowGroup.id])
    case .edit(let workflowGroup):
      let workflowGroup = SidebarMapper.map(workflowGroup, applicationStore: applicationStore)
      groupPublisher.publish(workflowGroup)
      render([workflowGroup.id])
    }
  }

  func handle(_ action: ContentListView.Action) {
    // TODO: We should get rid of this guard.
    guard let id = groupSelectionManager.selections.first,
          var group = store.group(withId: id) else { return }

    ContentViewActionReducer.reduce(
      action,
      groupStore: store,
      selectionManager: contentSelectionManager,
      group: &group)

    switch action {
    case .addWorkflow(let id):
      store.updateGroups([group])
      withAnimation {
        render([group.id], selectionOverrides: [id])
      }
      NotificationCenter.default.post(.newWorkflow)
    case .selectWorkflow:
      break
    case .refresh(let ids):
      render(ids, calculateSelections: true)
    default:
      store.updateGroups([group])
      render([group.id], calculateSelections: true)
    }
  }

  func handle(_ action: DetailView.Action) {
    switch action {
    case .singleDetailView(let action):
      switch action {
      case .applicationTrigger:
        render(groupSelectionManager.selections, calculateSelections: false)
      case .commandView(_, let action):
        switch action {
        case .changeDelay, .toggleNotify, .run: break
        case .toggleEnabled, .updateName, .modify, .remove:
          render(groupSelectionManager.selections, calculateSelections: false)
        }
      case .dropUrls, .duplicate, .moveCommand, .removeCommands,
          .removeTrigger, .setIsEnabled, .updateKeyboardShortcuts,
          .updateName, .updateSnippet:
        render(groupSelectionManager.selections, calculateSelections: false)
      case .togglePassthrough, .runWorkflow, .trigger,
           .updateExecution, .updateHoldDuration:
        break
      }
    }
  }

  // MARK: Private methods

  private func render(_ groupIds: Set<GroupViewModel.ID>,
                      calculateSelections: Bool = false,
                      selectionOverrides: Set<Workflow.ID>? = nil) {
    Benchmark.shared.start("ContentCoordinator.render")
    defer { Benchmark.shared.stop("ContentCoordinator.render") }

    var viewModels = [ContentViewModel]()
    var newSelections = Set<ContentViewModel.ID>()
    var selectedWorkflowIds = contentSelectionManager.selections
    var firstViewModel: ContentViewModel?

    for offset in store.groups.indices {
      let group = store.groups[offset]
      if groupIds.contains(group.id) {
        for wOffset in group.workflows.indices {
          let workflow = group.workflows[wOffset]
          let viewModel = mapper.map(workflow)

          if wOffset == 0 {
            firstViewModel = viewModel
          }

          viewModels.append(viewModel)

          if calculateSelections &&
              !selectedWorkflowIds.isEmpty &&
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
      } else if !contentSelectionManager.selections.intersection(viewModels.map(\.id)).isEmpty {
        newSelections = contentSelectionManager.selections
      } else if newSelections.isEmpty, let first = firstViewModel {
        newSelections = [first.id]
      }
      contentSelectionManager.publish(newSelections)
    } else if let selectionOverrides {
      contentSelectionManager.publish(selectionOverrides)
      if let first = selectionOverrides.first {
        contentSelectionManager.setLastSelection(first)
      }
    }
  }
}

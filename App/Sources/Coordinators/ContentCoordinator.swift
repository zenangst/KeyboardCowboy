import Combine
import SwiftUI

@MainActor
final class ContentCoordinator {
  private let store: GroupStore
  private let mapper: ContentModelMapper
  private let applicationStore: ApplicationStore

  let groupSelectionManager: SelectionManager<GroupViewModel>
  let selectionManager: SelectionManager<ContentViewModel>
  let publisher: ContentPublisher = ContentPublisher()

  init(_ store: GroupStore,
       applicationStore: ApplicationStore,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>) {
    self.applicationStore = applicationStore
    self.store = store
    self.groupSelectionManager = groupSelectionManager
    self.mapper = ContentModelMapper()
    self.selectionManager = contentSelectionManager

    enableInjection(self, selector: #selector(injected(_:)))

    // Set initial selection
    if let initialGroupSelection = groupSelectionManager.lastSelection,
      let initialWorkflowSelection = contentSelectionManager.lastSelection {
      render([initialGroupSelection], selectionOverrides: [initialWorkflowSelection])
    }
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .openScene:
      break
    case .addConfiguration:
      break
    case .selectConfiguration:
      break
    case .selectGroups(let ids):
      handle(.rerender(ids))
    case .moveGroups:
      break
    case .removeGroups:
      break
    }
  }

  func handle(_ action: ContentView.Action) {
    // TODO: We should get rid of this guard.
    guard let id = groupSelectionManager.selections.first,
          var group = store.group(withId: id) else { return }

    ContentViewActionReducer.reduce(
      action,
      groupStore: store,
      selectionPublisher: selectionManager,
      group: &group)

    switch action {
    case .addWorkflow(let id):
      store.updateGroups([group])
      render([group.id], selectionOverrides: [id])
    case .selectWorkflow:
      break
    case .rerender(let ids):
      render(ids, calculateSelections: true)
    default:
      store.updateGroups([group])
      render([group.id], calculateSelections: true)
    }
  }

  func handle(_ action: DetailView.Action) {
    switch action {
    case .singleDetailView:
      render(groupSelectionManager.selections, calculateSelections: false)
    }
  }

  // MARK: Private methods

  @objc private func injected(_ notification: Notification) {
    guard didInject(self, notification: notification) else { return }
    withAnimation(.easeInOut(duration: 0.2)) {
      render(groupSelectionManager.selections, calculateSelections: true)
    }
  }

  private func render(_ groupIds: Set<GroupViewModel.ID>,
                      calculateSelections: Bool = false,
                      selectionOverrides: Set<Workflow.ID>? = nil) {
    Benchmark.start("ContentCoordinator.render")
    defer { Benchmark.finish("ContentCoordinator.render") }

    var viewModels = [ContentViewModel]()
    var newSelections = Set<ContentViewModel.ID>()
    var selectedWorkflowIds = selectionManager.selections
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

    if calculateSelections {
      if publisher.data.isEmpty {
        if newSelections.isEmpty, let first = viewModels.first {
          newSelections = [first.id]
        }
      } else if !selectionManager.selections.intersection(viewModels.map(\.id)).isEmpty {
        newSelections = selectionManager.selections
      } else if newSelections.isEmpty, let first = firstViewModel {
        newSelections = [first.id]
      }
      selectionManager.selections = newSelections
    } else if let selectionOverrides {
      selectionManager.selections = selectionOverrides
    }

    publisher.publish(viewModels)
  }
}

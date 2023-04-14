import Combine
import SwiftUI

struct ContentSelectionIds: Identifiable, Hashable {
  var id: Int { groupIds.hashValue + workflowIds.hashValue }

  let groupIds: [GroupViewModel.ID]
  let workflowIds: [ContentViewModel.ID]
}

@MainActor
final class ContentCoordinator {
  static private var appStorage: AppStorageStore = .init()
  private var subscription: AnyCancellable?
  private let store: GroupStore
  private let mapper: ContentModelMapper
  private let applicationStore: ApplicationStore

  let selectionPublisher: ContentSelectionIdsPublisher
  let publisher: ContentPublisher = ContentPublisher()

  init(_ store: GroupStore, applicationStore: ApplicationStore,
       selectionPublisher: ContentSelectionIdsPublisher) {
    self.applicationStore = applicationStore
    self.store = store
    self.selectionPublisher = selectionPublisher
    self.mapper = ContentModelMapper()

    enableInjection(self, selector: #selector(injected(_:)))
  }

  func subscribe(to publisher: Published<WorkflowGroupIds>.Publisher) {
    subscription = publisher
      .dropFirst()
      .debounce(for: .milliseconds(40), scheduler: RunLoop.main)
      .removeDuplicates()
      .sink { [weak self] group in
        self?.render(group.ids, calculateSelections: true)
      }
  }

  func handle(_ action: ContentView.Action) async {
    guard selectionPublisher.model.groupIds.count == 1,
          let id = selectionPublisher.model.groupIds.first,
          var group = store.group(withId: id) else { return }

    await ContentViewActionReducer.reduce(
      action, selectionPublisher: selectionPublisher,
      group: &group)

    switch action {
    case .addWorkflow(let id):
      store.updateGroups([group])
      render([group.id], selectionOverrides: [id])
      publisher.publish(selections: [id])
    case .selectWorkflow(let workflowIds, _):
      Self.appStorage.workflowIds <- Set(workflowIds)
    default:
      store.updateGroups([group])
      render([group.id], calculateSelections: true)
    }
  }

  func handle(_ action: DetailView.Action) {
    switch action {
    case .singleDetailView:
      render(selectionPublisher.model.groupIds, calculateSelections: false)
    }
  }

  // MARK: Private methods

  @objc private func injected(_ notification: Notification) {
    guard didInject(self, notification: notification) else { return }
    withAnimation(.easeInOut(duration: 0.2)) {
      render(Array(Self.appStorage.groupIds), calculateSelections: true)
    }
  }

  private func render(_ groupIds: [GroupViewModel.ID],
                      calculateSelections: Bool = false,
                      selectionOverrides: [Workflow.ID]? = nil) {
    Benchmark.start("ContentCoordinator.render")
    defer { Benchmark.finish("ContentCoordinator.render") }

    var viewModels = [ContentViewModel]()
    var newSelections = [ContentViewModel.ID]()
    var selectedWorkflowIds = Self.appStorage.workflowIds
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
            newSelections.append(viewModel.id)
          }
        }
      }
    }

    if calculateSelections {
      if publisher.models.isEmpty {
        if newSelections.isEmpty, let first = viewModels.first {
          newSelections = [first.id]
        }
      } else if !publisher.selections.intersection(viewModels.map(\.id)).isEmpty {
        newSelections = Array(publisher.selections)
      } else if newSelections.isEmpty, let first = firstViewModel {
        newSelections = [first.id]
      }
      selectionPublisher.publish(ContentSelectionIds(groupIds: groupIds,
                                                     workflowIds: newSelections) )
    }

    if let selectionOverrides {
      publisher.publish(viewModels, selections: selectionOverrides)
    } else {
      publisher.publish(viewModels, selections: calculateSelections ? newSelections : nil)
    }
  }
}

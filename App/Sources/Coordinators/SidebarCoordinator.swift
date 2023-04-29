import Combine
import SwiftUI

@MainActor
final class SidebarCoordinator {
  private var subscription: AnyCancellable?

  private let applicationStore: ApplicationStore
  private let store: GroupStore

  let publisher = GroupsPublisher()

  let configSelectionManager: SelectionManager<ConfigurationViewModel>
  let selectionManager: SelectionManager<GroupViewModel>

  init(_ store: GroupStore, applicationStore: ApplicationStore,
       configSelectionManager: SelectionManager<ConfigurationViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>
  ) {
    self.applicationStore = applicationStore
    self.store = store
    self.configSelectionManager = configSelectionManager
    self.selectionManager = groupSelectionManager

    // Initial load
    // Configurations are loaded asynchronously, so we need to wait for them to be loaded
    subscription = store.$groups
      .dropFirst()
      .sink { [weak self] groups in
        self?.render(groups)
        self?.subscription = nil
      }

    enableInjection(self, selector: #selector(injected(_:)))
  }

  func handle(_ context: EditWorkflowGroupWindow.Context) {
    switch context {
    case .add(let group):
      store.add(group)
      selectionManager.selections = [group.id]
      render(store.groups)
    case .edit(let group):
      store.updateGroups([group])
      selectionManager.selections = [group.id]
      render(store.groups)
    }
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .selectConfiguration:
      render(store.groups)
    case .addConfiguration, .openScene, .selectGroups:
      break
    case .removeGroups(let ids):
      var newIndex = 0
      for (index, group) in store.groups.enumerated() {
        if ids.contains(group.id) { newIndex = index }
      }

      ids.forEach { selectionManager.selections.remove($0) }
      store.removeGroups(with: ids)
      render(store.groups)

      // Clear the selection if the group store is empty
      if store.groups.isEmpty {
        selectionManager.selections = []
      } else {
        // Check that we are not out of bounds
        if newIndex >= store.groups.count {
          newIndex = max(store.groups.count - 1, 0)
        }
        selectionManager.selections = [
          store.groups[newIndex].id
        ]
      }
    case .moveGroups(let source, let destination):
      store.move(source: source, destination: destination)
      render(store.groups)
    }
  }

  // MARK: Private methods

  @objc private func injected(_ notification: Notification) {
    guard didInject(self, notification: notification) else { return }
    withAnimation(.easeInOut(duration: 0.2)) {
      render(store.groups)
    }
  }

  private func render(_ workflowGroups: [WorkflowGroup]) {
    Benchmark.start("SidebarCoordinator.render")
    defer { Benchmark.finish("SidebarCoordinator.render") }

    var groups = [GroupViewModel]()
    groups.reserveCapacity(workflowGroups.count)
    var newSelections: Set<GroupViewModel.ID>?
    let publisherIsEmpty = publisher.data.isEmpty

    for (offset, workflowGroup) in workflowGroups.enumerated() {
      let group = SidebarMapper.map(workflowGroup, applicationStore: applicationStore)

      groups.append(group)

      if publisherIsEmpty {
        if newSelections == nil || selectionManager.selections.contains(group.id) {
          newSelections = []
        }

        if selectionManager.selections.contains(group.id) {
          newSelections?.insert(group.id)
        } else if offset == 0 {
          newSelections?.insert(group.id)
        }
      }
    }

    if groups.isEmpty {
      newSelections = []
    }

    publisher.publish(groups)

    if let newSelections {
      selectionManager.selections = newSelections
    }
  }
}

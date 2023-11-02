import Combine
import SwiftUI

@MainActor
final class SidebarCoordinator {
  private var subscription: AnyCancellable?

  private let applicationStore: ApplicationStore
  private let configSelectionManager: SelectionManager<ConfigurationViewModel>
  private let selectionManager: SelectionManager<GroupViewModel>
  private let store: GroupStore

  let publisher = GroupsPublisher()

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
      .sink { [weak self] groups in
        self?.render(groups)
        self?.subscription = nil
      }

    enableInjection(self, selector: #selector(injected(_:)))
  }

  func handle(_ context: EditWorkflowGroupWindow.Context) {
    let storeWasEmpty = store.groups.isEmpty
    let groupId: GroupViewModel.ID
    switch context {
    case .add(let group):
      groupId = group.id
      store.add(group)
      selectionManager.selectedColor = Color(hex: group.color)
    case .edit(let group):
      groupId = group.id
      store.updateGroups([group])
      selectionManager.selectedColor = Color(hex: group.color)
    }
    selectionManager.publish([groupId])
    if storeWasEmpty {
        withAnimation(WorkflowCommandListView.animation) {
          render(store.groups)
        }
    } else {
      render(store.groups)
    }
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .refresh:
      render(store.groups)
    case .updateConfiguration:
      break
    case .selectConfiguration(let id):
      if let firstGroup = store.groups.first(where: { $0.id == id }) {
        selectionManager.publish([firstGroup.id])
        selectionManager.selectedColor = Color(hex: firstGroup.color)
      } else {
        selectionManager.publish([])
      }
      render(store.groups)
    case .deleteConfiguraiton:
      if let firstGroup = store.groups.first {
        selectionManager.publish([firstGroup.id])
        selectionManager.selectedColor = Color(hex: firstGroup.color)
      } else {
        selectionManager.publish([])
      }
      render(store.groups)
    case .selectGroups(let ids):
      if ids.count == 1, let id = ids.first, let group = store.group(withId: id) {
        let nsColor = NSColor(hex: group.color).blended(withFraction: 0.4, of: .black)!
        selectionManager.selectedColor = Color(nsColor: nsColor)
      } else {
        selectionManager.selectedColor = Color.accentColor
      }
    case .addConfiguration:
      render(store.groups)
    case .openScene:
      break
    case .removeGroups(let ids):
      var newIndex = 0
      for (index, group) in store.groups.enumerated() {
        if ids.contains(group.id) { newIndex = index }
      }

      ids.forEach { selectionManager.selections.remove($0) }
      store.removeGroups(with: ids)

      if store.groups.isEmpty {
        withAnimation(.easeInOut(duration: 0.3)) {
          render(store.groups)
        }
      } else {
        render(store.groups)
      }

      // Clear the selection if the group store is empty
      if store.groups.isEmpty {
        selectionManager.publish([])
      } else {
        // Check that we are not out of bounds
        if newIndex >= store.groups.count {
          newIndex = max(store.groups.count - 1, 0)
        }
        selectionManager.publish([
          store.groups[newIndex].id
        ])
      }
    case .moveGroups(let source, let destination):
      store.move(source: source, destination: destination)
      render(store.groups)
    case .copyWorkflows(let workflowIds, let groupId):
      store.copy(workflowIds, to: groupId)
    case .moveWorkflows(let workflowIds, let groupId):
      store.move(workflowIds, to: groupId)
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

    if let newSelections, selectionManager.selections != newSelections {
      selectionManager.selections = newSelections
    }
  }
}

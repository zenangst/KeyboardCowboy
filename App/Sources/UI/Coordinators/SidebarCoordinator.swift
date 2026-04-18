import Bonzai
import Combine
import SwiftUI

@MainActor
final class SidebarCoordinator {
  private var subscription: AnyCancellable?

  private let applicationStore: ApplicationStore
  private let selectionManager: SelectionManager<GroupViewModel>
  private let store: GroupStore

  let publisher = GroupsPublisher()

  init(_ store: GroupStore, applicationStore: ApplicationStore,
       groupSelectionManager: SelectionManager<GroupViewModel>) {
    self.applicationStore = applicationStore
    self.store = store
    selectionManager = groupSelectionManager

    // Initial load
    // Configurations are loaded asynchronously, so we need to wait for them to be loaded
    subscription = store.$groups
      .sink { [weak self] groups in
        self?.initialLoad(groups)
      }

    enableInjection(self, selector: #selector(injected(_:)))
  }

  func handle(_ context: EditWorfklowGroupView.Context) {
    let storeWasEmpty = store.groups.isEmpty
    let groupId: GroupViewModel.ID
    switch context {
    case let .add(group):
      groupId = group.id
      store.add(group)
      ColorPublisher.shared.publish(Color(hex: group.color))
    case let .edit(group):
      groupId = group.id
      store.updateGroups([group])
      ColorPublisher.shared.publish(Color(hex: group.color))
    }
    selectionManager.publish([groupId])
    if storeWasEmpty {
      withAnimation(CommandList.animation) {
        render(store.groups)
      }
    } else {
      render(store.groups)
    }
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .updateConfiguration, .openScene, .userMode:
      break
    case .refresh:
      render(store.groups)
    case .selectConfiguration:
      render(store.groups)
    case .deleteConfiguration:
      render(store.groups)
    case let .selectGroups(ids):
      synchronizeSelection(with: store.groups, preferredSelections: ids)
    case .addConfiguration:
      render(store.groups)
    case let .removeGroups(ids):
      var newIndex = 0
      for (index, group) in store.groups.enumerated() {
        if ids.contains(group.id) { newIndex = index }
      }

      var modifiedSelections = selectionManager.selections
      ids.forEach { modifiedSelections.remove($0) }
      selectionManager.publish(modifiedSelections)
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
          store.groups[newIndex].id,
        ])
      }
    case let .moveGroups(source, destination):
      store.move(source: source, destination: destination)
      render(store.groups)
    case let .copyWorkflows(workflowIds, groupId):
      store.copy(workflowIds, to: groupId)
    case let .moveWorkflows(workflowIds, groupId):
      store.move(workflowIds, to: groupId)
    }
  }

  // MARK: Private methods

  func initialLoad(_ groups: [WorkflowGroup]) {
    render(groups)
    if groups.isEmpty {
      subscription = nil
    }
  }

  @objc private func injected(_ notification: Notification) {
    guard didInject(self, notification: notification) else { return }

    withAnimation(.easeInOut(duration: 0.2)) {
      render(store.groups)
    }
  }

  private func render(_ workflowGroups: [WorkflowGroup]) {
    Benchmark.shared.start("SidebarCoordinator.render")
    defer { Benchmark.shared.stop("SidebarCoordinator.render") }

    var groups = [GroupViewModel]()
    groups.reserveCapacity(workflowGroups.count)

    for workflowGroup in workflowGroups {
      let group = SidebarMapper.map(workflowGroup, applicationStore: applicationStore)

      groups.append(group)
    }

    publisher.publish(groups)
    synchronizeSelection(with: workflowGroups)
  }

  private func synchronizeSelection(with workflowGroups: [WorkflowGroup], preferredSelections: Set<GroupViewModel.ID>? = nil) {
    let validIds = Set(workflowGroups.map(\.id))
    let currentSelections = preferredSelections ?? selectionManager.selections
    let normalizedSelections = currentSelections.intersection(validIds)

    if workflowGroups.isEmpty {
      selectionManager.publish([])
      ColorPublisher.shared.publish(.accentColor)
      return
    }

    if !normalizedSelections.isEmpty {
      selectionManager.publish(normalizedSelections)
      updateColor(using: workflowGroups, selections: normalizedSelections)
      return
    }

    if let lastSelection = selectionManager.lastSelection,
       validIds.contains(lastSelection) {
      selectionManager.publish([lastSelection])
      updateColor(using: workflowGroups, selections: [lastSelection])
      return
    }

    guard let firstGroup = workflowGroups.first else { return }

    selectionManager.publish([firstGroup.id])
    updateColor(using: workflowGroups, selections: [firstGroup.id])
  }

  private func updateColor(using workflowGroups: [WorkflowGroup], selections: Set<GroupViewModel.ID>) {
    guard selections.count == 1,
          let id = selections.first,
          let group = workflowGroups.first(where: { $0.id == id }),
          let nsColor = NSColor(hex: group.color).blended(withFraction: 0.4, of: .black)
    else {
      ColorPublisher.shared.publish(.accentColor)
      return
    }

    ColorPublisher.shared.publish(Color(nsColor: nsColor))
  }
}

import Combine
import SwiftUI

@MainActor
final class SidebarCoordinator {
  static private var appStorage: AppStorageStore = .init()
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

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .addConfiguration, .selectConfiguration, .openScene:
      break
    case .selectGroups(let groups):
      Self.appStorage.groupIds = Set(groups)
    case .removeGroups(let ids):
      for id in ids {
        Self.appStorage.groupIds.remove(id)
      }
      store.removeGroups(with: ids)
    case .moveGroups(let source, let destination):
      store.move(source: source, destination: destination)
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
        if newSelections == nil || Self.appStorage.groupIds.contains(group.id) {
          newSelections = []
        }

        if Self.appStorage.groupIds.contains(group.id) {
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

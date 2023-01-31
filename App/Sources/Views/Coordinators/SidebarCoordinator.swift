import Combine
import SwiftUI

struct WorkflowGroupIds: Identifiable, Hashable {
  var id: WorkflowGroup.ID { ids.rawValue }
  let ids: [WorkflowGroup.ID]
}

@MainActor
final class SidebarCoordinator {
  static private var appStorage: AppStorageStore = .init()
  private var subscription: AnyCancellable?

  private let applicationStore: ApplicationStore
  private let store: GroupStore

  let publisher = GroupsPublisher()
  let groupIdsPublisher: GroupIdsPublisher
  let workflowIdsPublisher: ContentSelectionIdsPublisher

  init(_ store: GroupStore,
       applicationStore: ApplicationStore,
       groupIdsPublisher: GroupIdsPublisher,
       workflowIdsPublisher: ContentSelectionIdsPublisher) {
    self.applicationStore = applicationStore
    self.workflowIdsPublisher = workflowIdsPublisher
    self.groupIdsPublisher = groupIdsPublisher
    self.store = store

    subscribe(to: store.$groups)
    enableInjection(self, selector: #selector(injected(_:)))
  }

  func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    subscription = publisher
      .dropFirst()
      .sink { [weak self] groups in
        self?.render(groups)
      }
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .selectConfiguration, .openScene:
      break
    case .selectGroups(let groups):
      Self.appStorage.groupIds = Set(groups)
      groupIdsPublisher.publish(.init(ids: groups))
    case .removeGroups(let ids):
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

  private func render(_ groups: [WorkflowGroup]) {
    Benchmark.start("SidebarCoordinator.render")
    defer {
      Benchmark.finish("SidebarCoordinator.render")
    }
    var viewModels = [GroupViewModel]()
    viewModels.reserveCapacity(groups.count)
    var newSelections: [GroupViewModel.ID]?
    let publisherIsEmpty = publisher.models.isEmpty && publisher.selections.isEmpty

    for (offset, group) in groups.enumerated() {
      let viewModel = SidebarMapper.map(group, applicationStore: applicationStore)

      viewModels.append(viewModel)

      if publisherIsEmpty {
        if newSelections?.isEmpty == true || Self.appStorage.groupIds.contains(group.id) {
          newSelections = []
        }

        if Self.appStorage.groupIds.contains(group.id) {
          newSelections?.append(group.id)
        } else if offset == 0 {
          newSelections?.append(group.id)
        }
      }
    }

    publisher.publish(viewModels, selections: newSelections)
  }
}

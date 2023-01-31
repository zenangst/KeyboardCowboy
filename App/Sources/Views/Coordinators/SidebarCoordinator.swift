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
    var newIds = Set<String>()
    newIds.reserveCapacity(groups.count)
    let viewModels = groups.map { group in
      newIds.insert(group.id)
      return group.asViewModel(group.rule?.iconPath(using: applicationStore))
    }

    let selectedIds = publisher.selections
      .filter({ newIds.contains($0) })
    var newSelections = [GroupViewModel.ID]()
    if selectedIds.isEmpty {
      if publisher.models.isEmpty && !Self.appStorage.groupIds.isDisjoint(with: newIds) {
        newSelections = viewModels.filter({ Self.appStorage.groupIds.contains($0.id) }).map(\.id)
      } else if let first = viewModels.first {
        newSelections = [first.id]
      }
    }
    else {
      newSelections = viewModels.filter { selectedIds.contains($0.id) }.map(\.id)
    }

    publisher.publish(viewModels, selections: newSelections)
  }
}

extension Array where Element == WorkflowGroup {
  func asViewModels(store: ApplicationStore) -> [GroupViewModel] {
    self.map { $0.asViewModel($0.rule?.iconPath(using: store)) }
  }
}

extension WorkflowGroup {
  func asViewModel(_ iconPath: String?) -> GroupViewModel {
    GroupViewModel(
      id: id,
      name: name,
      iconPath: iconPath,
      color: color,
      symbol: symbol,
      count: workflows.count)
  }
}

private extension Rule {
  func iconPath(using applicationStore: ApplicationStore) -> String? {
    if let bundleIdentifier = bundleIdentifiers.first,
       let app = applicationStore.application(for: bundleIdentifier) {
      return app.path
    }
    return nil
  }
}

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
  private let contentPublisher: ContentPublisher

  let publisher = GroupsPublisher()
  let groupIdsPublisher: GroupIdsPublisher
  let workflowIdsPublisher: ContentSelectionIdsPublisher

  init(_ store: GroupStore,
       contentPublisher: ContentPublisher,
       applicationStore: ApplicationStore,
       groupIdsPublisher: GroupIdsPublisher,
       workflowIdsPublisher: ContentSelectionIdsPublisher) {
    self.applicationStore = applicationStore
    self.contentPublisher = contentPublisher
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
      let ids = groups.map(\.id)
      Self.appStorage.groupIds = Set(ids)
      groupIdsPublisher.publish(.init(ids: ids))
    case .removeGroups(let ids):
      store.removeGroups(with: ids)
    case .moveGroups(let source, let destination):
      store.move(source: source, destination: destination)
    }
  }

  func handle(_ action: ContentView.Action) {
    guard publisher.selections.count == 1,
          let id = publisher.selections.first?.id,
          var group = store.group(withId: id) else { return }

    switch action {
    case .addWorkflow:
      let workflow = Workflow.empty()
      group.workflows.append(workflow)
      store.updateGroups([group])
    case .removeWorflows(let ids):
      group.workflows.removeAll(where: { ids.contains($0.id) })
      store.updateGroups([group])
    case .moveWorkflows(let source, let destination):
      group.workflows.move(fromOffsets: source, toOffset: destination)
      store.updateGroups([group])

      let viewModels = group.workflows.enumerated().map {
        let groupName: String? = $0 == 1 ? group.name : nil
        return $1.asViewModel(groupName)
      }
      let selections: [ContentViewModel]?

      if !publisher.selections.isEmpty {
        var newSelections = [ContentViewModel]()
        for model in contentPublisher.selections {
          guard let newModel = viewModels.first(where: { $0.id == model.id }) else {
            return
          }

          newSelections.append(newModel)
        }
        selections = newSelections
      } else if !viewModels.isEmpty && destination - 1 < viewModels.count  {
        let first = viewModels[max(destination - 1, 0)]
        selections = [first]
      } else {
        selections = []
      }
      contentPublisher.publish(viewModels, selections: selections)
    case .selectWorkflow(let workflows, let groupIds):
      let workflowIds = workflows.map(\.id)
      workflowIdsPublisher.publish(.init(groupIds: groupIds,
                                         workflowIds: workflowIds))
      Self.appStorage.workflowIds = Set(workflowIds)
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

    let selectedIds = publisher
      .selections.map { $0.id }
      .filter({ newIds.contains($0) })
    var newSelections = [GroupViewModel]()
    if selectedIds.isEmpty {
      if publisher.models.isEmpty && !Self.appStorage.groupIds.isDisjoint(with: newIds) {
        newSelections = viewModels.filter { Self.appStorage.groupIds.contains($0.id) }
      } else if let first = viewModels.first {
        newSelections = [first]
      }
    }
    else {
      newSelections = viewModels.filter { selectedIds.contains($0.id) }
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

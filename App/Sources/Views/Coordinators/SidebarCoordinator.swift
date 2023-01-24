import Combine
import SwiftUI

final class SidebarCoordinator {
  private var subscription: AnyCancellable?
  private let applicationStore: ApplicationStore
  private let store: GroupStore

  let publisher = GroupsPublisher()
  let contentPublisher: ContentPublisher

  init(_ store: GroupStore,
       contentPublisher: ContentPublisher,
       applicationStore: ApplicationStore) {
    self.applicationStore = applicationStore
    self.contentPublisher = contentPublisher
    self.store = store

    subscription = store.$groups
      .sink { [weak self] groups in
        self?.render(groups)
      }
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .selectConfiguration, .openScene, .selectGroups:
      break
    case .removeGroups(let ids):
      store.removeGroups(with: ids)
    case .moveGroups(let source, let destination):
      store.move(source: source, destination: destination)
    }
  }

  @MainActor
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
      contentPublisher.publish(group.workflows.map { $0.asViewModel() })
    default:
      break
    }
  }
  
  private func render(_ groups: [WorkflowGroup]) {
    Task {
      var newIds = [String]()
      let viewModels = groups.map { group in
        newIds.append(group.id)
        return group.asViewModel(group.rule?.image(using: applicationStore))
      }

      let selectedIds = publisher
        .selections.map { $0.id }
        .filter({ newIds.contains($0) })
      var newSelections: [GroupViewModel]
      if selectedIds.isEmpty, let first = viewModels.first {
        newSelections = [first]
      } else {
        newSelections = viewModels.filter { selectedIds.contains($0.id) }
      }

      await publisher.publish(viewModels, selections: newSelections)
    }
  }
}

extension Array where Element == WorkflowGroup {
  func asViewModels(store: ApplicationStore) -> [GroupViewModel] {
    self.map { $0.asViewModel($0.rule?.image(using: store)) }
  }
}

extension WorkflowGroup {
  func asViewModel(_ image: NSImage?) -> GroupViewModel {
    GroupViewModel(
      id: id,
      name: name,
      image: image,
      color: color,
      symbol: symbol,
      count: workflows.count)
  }
}

private extension Rule {
  func image(using applicationStore: ApplicationStore) -> NSImage? {
    if let app = bundleIdentifiers
      .compactMap({ applicationStore.application(for: $0) })
      .first {
      return NSWorkspace.shared.icon(forFile: app.path)
    }
    return nil
  }
}

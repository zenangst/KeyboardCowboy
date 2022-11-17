import Combine
import SwiftUI

final class SidebarCoordinator {
  private var subscription: AnyCancellable?
  private let applicationStore: ApplicationStore
  private let store: GroupStore

  let publisher = GroupsPublisher()

  init(_ store: GroupStore, applicationStore: ApplicationStore) {
    self.applicationStore = applicationStore
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
    switch action {
    case .addWorkflow:
      guard publisher.selections.count == 1,
            let id = publisher.selections.first?.id,
            var group = store.group(withId: id) else { return }

      let workflow = Workflow.empty()
      group.workflows.append(workflow)
      store.updateGroups([group])
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

private extension WorkflowGroup {
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

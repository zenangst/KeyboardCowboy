import Combine
import SwiftUI

final class SidebarCoordinator {
  private var subscription: AnyCancellable?
  private let applicationStore: ApplicationStore
  private let store: GroupStore

  let publisher = GroupsPublisher()

  @Environment(\.openWindow) private var openWindow

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
    case .onSelect:
      break
    }
  }

  private func render(_ groups: [WorkflowGroup]) {
    Task {
      let viewModels = groups.map { group in
        group.asViewModel(group.rule?.image(using: applicationStore))
      }

      let selectedIds = publisher.selections.map { $0.id }
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

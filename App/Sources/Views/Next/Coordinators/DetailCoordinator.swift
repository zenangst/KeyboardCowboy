import SwiftUI

final class DetailCoordinator {
  let store: GroupStore
  let publisher: DetailPublisher = .init(.empty)

  init(_ store: GroupStore) {
    self.store = store
  }

  func handle(_ action: ContentView.Action) {
    switch action {
    case .onSelect(let content):
      Task { await render(content) }
    }
  }

  private func render(_ content: [ContentViewModel]) async {
    let ids = content.map(\.id)
    let workflows = store.groups
      .flatMap(\.workflows)
      .filter { ids.contains($0.id) }

    var viewModels: [DetailViewModel] = []
    for workflow in workflows {
      let commands = workflow.commands
        .map { command in
          DetailViewModel.CommandViewModel(
            id: command.id,
            name: command.name,
            image: nil,
            isEnabled: command.isEnabled
          )
        }

      let viewModel = DetailViewModel(
        id: workflow.id,
        name: workflow.name,
        isEnabled: workflow.isEnabled,
        trigger: workflow.trigger?.asViewModel(),
        commands: commands)
      viewModels.append(viewModel)
    }

    let state: DetailViewState
    if viewModels.count > 1 {
      state = .multiple(viewModels)
    } else if let viewModel = viewModels.first {
      state = .single(viewModel)
    } else {
      state = .empty
    }

    await publisher.publish(state)
  }
}

extension Workflow.Trigger {
  func asViewModel() -> DetailViewModel.Trigger {
    switch self {
    case .application:
      return .applications("foo")
    case .keyboardShortcuts(let shortcuts):
      let value = shortcuts.map {
        $0.modifersDisplayValue
      }
      return .keyboardShortcuts(value)
    }
  }
}

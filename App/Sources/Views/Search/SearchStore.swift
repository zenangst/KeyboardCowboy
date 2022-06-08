import Apps
import Combine
import Foundation

final class SearchStore: ObservableObject {
  @Published var query: String = "" {
    didSet { search(query) }
  }
  @Published private(set) var results: [SearchResult] = .init()

  private var subscription: AnyCancellable?
  private var groups: [WorkflowGroup] = [WorkflowGroup]()

  let store: GroupStore

  init(store: GroupStore, results: [SearchResult]) {
    self.store = store
    _results = .init(initialValue: results)

    subscription = store.$groups.sink { [weak self] groups in
      self?.groups = groups
    }
  }

  func search(_ query: String) {
    if query.isEmpty {
      results = []
      return
    }

    let workflows = groups.flatMap { $0.workflows }
    let commands = workflows.flatMap { $0.commands }

    let matchedWorkflows = workflows.filter { workflow in
      workflow.name.containsCaseSensitive(query)
    }

    let matchedCommands = commands.filter { command in
      command.name.containsCaseSensitive(query)
    }

    var results = [SearchResult]()

    for workflow in matchedWorkflows {
      results.append(.init(name: workflow.name, kind: .workflow(workflow)))
    }

    for command in matchedCommands {
      results.append(.init(name: command.name, kind: .command(command)))
    }

    self.results = results
  }
}

private extension String {
  func containsCaseSensitive(_ subject: String) -> Bool {
    self.lowercased().contains(subject.lowercased())
  }
}

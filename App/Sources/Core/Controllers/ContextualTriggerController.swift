import Combine
import Foundation

final class ContextualTriggerController {
  private var activateActions = [String: [Workflow]]()
  private var systemInfoSubscription: AnyCancellable?
  private var workflowGroupsSubscription: AnyCancellable?
  private var currentContext: SystemInfo.Context?

  func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    workflowGroupsSubscription = publisher.sink { [weak self] in
      self?.receive($0)
    }
  }

  func subscribe(to publisher: Published<SystemInfo.Context>.Publisher) {
    systemInfoSubscription = publisher
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] context in
      self?.evaluate(context)
    }
  }

  private func receive(_ groups: [WorkflowGroup]) {
    let workflows = groups.flatMap({ $0.workflows })

    workflows.forEach { workflow in
      guard workflow.isEnabled else { return }

      // Handle contextual commands.
    }
  }

  private func evaluate(_ context: SystemInfo.Context) {
    self.currentContext = context
  }
}

import Combine
import Cocoa

final class ApplicationTriggerController {
  private let commandEngine: CommandEngine
  private var activateActions = [String: [Workflow]]()
  private var bundleIdentifiers = [String]()
  private var closeActions = [String: [Workflow]]()
  private var openActions = [String: [Workflow]]()
  private var subscriptions: [AnyCancellable] = .init()

  init(_ commandEngine: CommandEngine) {
    self.commandEngine = commandEngine
  }

  func subscribe(to workspace: NSWorkspace) {
    workspace
      .publisher(for: \.runningApplications)
      .map { $0.compactMap { $0.bundleIdentifier } }
      .sink { [weak self] in
        self?.process($0)
      }
      .store(in: &subscriptions)

    workspace.publisher(for: \.frontmostApplication)
      .compactMap { $0 }
      .sink { [weak self] in
        self?.process($0)
      }
      .store(in: &subscriptions)
  }

  func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    publisher
      .sink { [weak self] groups in
        self?.receive(groups)
      }
      .store(in: &subscriptions)
  }

  private func receive(_ groups: [WorkflowGroup]) {
    self.openActions.removeAll()
    self.closeActions.removeAll()
    self.activateActions.removeAll()

    let workflows = groups.flatMap({ $0.workflows })
    for workflow in workflows where workflow.isEnabled {
      switch workflow.trigger {
      case .application(let triggers):
        for trigger in triggers {
          if trigger.contexts.contains(.closed) {
            var closeActions = self.closeActions[trigger.application.bundleIdentifier] ?? []
            closeActions.append(workflow)
            self.closeActions[trigger.application.bundleIdentifier] = closeActions
          }

          if trigger.contexts.contains(.launched) {
            var openActions = self.openActions[trigger.application.bundleIdentifier] ?? []
            openActions.append(workflow)
            self.openActions[trigger.application.bundleIdentifier] = openActions
          }

          if trigger.contexts.contains(.frontMost) {
            var activateActions = self.activateActions[trigger.application.bundleIdentifier] ?? []
            activateActions.append(workflow)
            self.activateActions[trigger.application.bundleIdentifier] = activateActions
          }
        }
      case .keyboardShortcuts, .none:
        break
      }
    }
  }

  // MARK: Private methods

  private func process(_ frontMostApplication: RunningApplication) {
    guard let bundleIdentifier = frontMostApplication.bundleIdentifier,
          let workflows = self.activateActions[bundleIdentifier] else { return }

    for workflow in workflows {
      runCommands(in: workflow)
    }
  }

  private func process(_ bundleIdentifiers: [String]) {
    let difference = bundleIdentifiers.difference(from: self.bundleIdentifiers)

    if difference.isEmpty { return }

    var workflows = [Workflow]()
    for change in difference {
      switch change {
      case .insert(_, let bundleIdentifier, _):
        workflows.append(contentsOf: openActions[bundleIdentifier] ?? [])
      case .remove(_, let bundleIdentifier, _):
        workflows.append(contentsOf: closeActions[bundleIdentifier] ?? [])
      }
    }

    for workflow in workflows {
      runCommands(in: workflow)
    }

    self.bundleIdentifiers = bundleIdentifiers
  }

  private func runCommands(in workflow: Workflow) {
    let commands = workflow.commands.filter(\.isEnabled)
    commandEngine.concurrentRun(commands)
  }
}

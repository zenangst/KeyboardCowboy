import Combine
import Cocoa

final class ApplicationTriggerController {
  private let commandRunner: CommandRunning
  private var activateActions = [String: [Workflow]]()
  private var bundleIdentifiers = [String]()
  private var closeActions = [String: [Workflow]]()
  private var frontmostApplicationSubscription: AnyCancellable?
  private var openActions = [String: [Workflow]]()
  private var runningApplicationsSubscription: AnyCancellable?
  private var workflowGroupsSubscription: AnyCancellable?

  init(_ commandRunner: CommandRunning) {
    self.commandRunner = commandRunner
  }

  func subscribe(to publisher: Published<[RunningApplication]>.Publisher) {
    runningApplicationsSubscription = publisher
      .map { $0.compactMap { $0.bundleIdentifier } }
      .sink { [weak self] in self?.process($0) }
  }

  func subscribe(to publisher: Published<RunningApplication?>.Publisher) {
    frontmostApplicationSubscription = publisher
      .compactMap { $0 }
      .sink { [weak self] in self?.process($0) }
  }

  func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    workflowGroupsSubscription = publisher.sink { [weak self] in self?.receive($0) }
  }

  // MARK: Private methods

  private func receive(_ groups: [WorkflowGroup]) {
    self.openActions.removeAll()
    self.closeActions.removeAll()
    self.activateActions.removeAll()

    let workflows = groups.flatMap({ $0.workflows })
    workflows.forEach { workflow in
      guard workflow.isEnabled else { return }
      switch workflow.trigger {
      case .application(let triggers):
        for trigger in triggers {
          if trigger.contexts.contains(.closed) {
            self.closeActions[trigger.application.bundleIdentifier, default: []].append(workflow)
          }

          if trigger.contexts.contains(.launched) {
            self.openActions[trigger.application.bundleIdentifier, default: []].append(workflow)
          }

          if trigger.contexts.contains(.frontMost) {
            self.activateActions[trigger.application.bundleIdentifier, default: []].append(workflow)
          }
        }
      case .keyboardShortcuts, .none:
        break
      }
    }
  }

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
    switch workflow.execution {
    case .concurrent:
      commandRunner.concurrentRun(commands)
    case .serial:
      commandRunner.serialRun(commands)
    }
  }
}

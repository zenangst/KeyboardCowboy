import Combine
import Cocoa
import MachPort

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

  func subscribe(to publisher: Published<[UserSpace.Application]>.Publisher) {
    runningApplicationsSubscription = publisher
      .sink { [weak self] in self?.process($0.map { $0.bundleIdentifier }) }
  }

  func subscribe(to publisher: Published<UserSpace.Application>.Publisher) {
    frontmostApplicationSubscription = publisher
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
      case .keyboardShortcuts, .snippet, .none:
        return
      }
    }
  }

  private func process(_ frontMostApplication: UserSpace.Application) {
    guard let workflows = self.activateActions[frontMostApplication.bundleIdentifier] else { return }

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
        if let openActions = openActions[bundleIdentifier] {
          workflows.append(contentsOf: openActions)
        }
      case .remove(_, let bundleIdentifier, _):
        if let closeActions = closeActions[bundleIdentifier] {
          workflows.append(contentsOf: closeActions)
        }
      }
    }

    workflows.forEach { runCommands(in: $0) }

    self.bundleIdentifiers = bundleIdentifiers
  }

  private func runCommands(in workflow: Workflow) {
    let commands = workflow.commands.filter(\.isEnabled)
    guard let machPortEvent = MachPortEvent.empty() else { return }
    switch workflow.execution {
    case .concurrent:
      commandRunner.concurrentRun(
        commands,
        checkCancellation: true,
        resolveUserEnvironment: workflow.resolveUserEnvironment(),
        shortcut: .empty(),
        machPortEvent: machPortEvent,
        repeatingEvent: false
      )
    case .serial:
      commandRunner.serialRun(
        commands,
        checkCancellation: true,
        resolveUserEnvironment: workflow.resolveUserEnvironment(),
        shortcut: .empty(),
        machPortEvent: machPortEvent,
        repeatingEvent: false
      )
    }
  }
}

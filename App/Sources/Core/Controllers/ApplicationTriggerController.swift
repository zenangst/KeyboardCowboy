import Combine
import Cocoa
import MachPort

final class ApplicationTriggerController {
  private let workflowRunner: WorkflowRunning
  private var activateActions = [String: [Workflow]]()
  private var bundleIdentifiers = [String]()
  private var closeActions = [String: [Workflow]]()
  private var frontmostApplicationSubscription: AnyCancellable?
  private var openActions = [String: [Workflow]]()
  private var runningApplicationsSubscription: AnyCancellable?
  private var workflowGroupsSubscription: AnyCancellable?
  private var hideActions = [String: [Workflow]]()

  private var previousApplication: UserSpace.Application?

  init(_ workflowRunner: WorkflowRunning) {
    self.workflowRunner = workflowRunner
  }

  func subscribe(to publisher: Published<[UserSpace.Application]>.Publisher) {
    runningApplicationsSubscription = publisher
      .sink { [weak self] in self?.process($0.map { $0.bundleIdentifier }) }
  }

  func subscribe(to publisher: Published<UserSpace.Application>.Publisher) {
    frontmostApplicationSubscription = publisher
      .sink { [weak self] in
        self?.process($0)
      }
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

          if trigger.contexts.contains(.resignFrontMost) {
            self.hideActions[trigger.application.bundleIdentifier, default: []].append(workflow)
          }
        }
      case .keyboardShortcuts, .snippet, .none:
        return
      }
    }
  }

  private func process(_ frontMostApplication: UserSpace.Application) {
    if let workflows = self.activateActions[frontMostApplication.bundleIdentifier] {
      workflows.forEach(workflowRunner.runCommands(in:))
    }

    if let previousApplication, let workflows = self.hideActions[previousApplication.bundleIdentifier] {
      workflows.forEach(workflowRunner.runCommands(in:))
    }

    previousApplication = frontMostApplication
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

    workflows.forEach(workflowRunner.runCommands(in:))

    self.bundleIdentifiers = bundleIdentifiers
  }

}
